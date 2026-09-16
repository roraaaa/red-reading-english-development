import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  bool get isCloud => true;

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUser);

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(result.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user!;
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return AppUser(id: user.uid, displayName: name.trim(), email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('You are not logged in.');
    try {
      // Firebase only allows deletion soon after signing in, so sign in again
      // first. This also fails fast on a wrong password, before anything has
      // been removed.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email ?? '', password: password),
      );
      // The data goes before the account: deleting the account first would
      // take away the permission needed to delete the data.
      await _deleteUserData(user.uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException catch (e) {
      throw AuthException(
        e.code == 'unavailable'
            ? 'No internet connection. Please check and try again.'
            : 'We could not delete your data. Please try again.',
      );
    }
  }

  /// Removes the profile and every saved score.
  ///
  /// Batched so that a long history goes in as few round trips as possible,
  /// and so a dropped connection leaves whole chunks deleted rather than a
  /// half-written document.
  Future<void> _deleteUserData(String uid) async {
    final profile = _firestore.collection('users').doc(uid);
    final scores = (await profile.collection('attempts').get()).docs;

    // A batch holds at most 500 writes, and the profile takes one of them.
    const perBatch = 499;
    for (var start = 0; start == 0 || start < scores.length; start += perBatch) {
      final batch = _firestore.batch();
      if (start == 0) batch.delete(profile);
      for (final score in scores.skip(start).take(perBatch)) {
        batch.delete(score.reference);
      }
      await batch.commit();
    }
  }

  AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(
          id: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
        );

  String _messageFor(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'That email address does not look right.',
    'user-disabled' => 'This account has been turned off.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'The email or password is not correct.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Please choose a stronger password (at least 6 characters).',
    'too-many-requests' => 'Too many tries. Please wait a moment and try again.',
    'requires-recent-login' => 'Please log out and log back in, then try again.',
    'network-request-failed' => 'No internet connection. Please check and try again.',
    _ => 'Something went wrong. Please try again.',
  };
}

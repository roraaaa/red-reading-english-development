import '../../domain/models/app_user.dart';

/// A message that is safe to show the reader.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  /// True when accounts are stored in the cloud (Firebase).
  bool get isCloud;

  /// Emits the signed-in user (or null) now and whenever it changes.
  Stream<AppUser?> userChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Permanently removes the account, the profile and every saved score.
  ///
  /// [password] is the account's current password. Asking for it proves the
  /// person tapping Delete is the account holder and not someone who picked
  /// up a phone that was left logged in.
  Future<void> deleteAccount({required String password});
}

import '../../domain/models/app_user.dart';

/// A message that is safe to show to the child or parent.
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
}

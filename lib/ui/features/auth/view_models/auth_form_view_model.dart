import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/auth_service.dart';

/// Shared by the login and sign-up screens. Navigation after a successful
/// sign-in is handled by the router's auth redirect.
class AuthFormViewModel extends ChangeNotifier {
  AuthFormViewModel({required AuthRepository auth}) : _auth = auth;

  final AuthRepository _auth;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isDemoMode => !_auth.isCloud;

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _auth.signIn(email: email, password: password));

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(() => _auth.signUp(name: name, email: email, password: password));

  /// Returns a message to show the user.
  Future<String> sendPasswordReset(String email) async {
    final problem = validateEmail(email);
    if (problem != null) return problem;
    try {
      await _auth.sendPasswordReset(email);
      return 'We sent a password reset link to $email.';
    } on AuthException catch (e) {
      return e.message;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('Auth error: $e');
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  static String? validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Please type your name.' : null;

  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please type an email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'That email address does not look right.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please type a password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }
}

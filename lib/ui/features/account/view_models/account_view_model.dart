import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/auth_service.dart';

class AccountViewModel extends ChangeNotifier {
  AccountViewModel({required AuthRepository auth}) : _auth = auth {
    _auth.addListener(_notify);
  }

  final AuthRepository _auth;

  bool _disposed = false;
  bool _isDeleting = false;
  String? _errorMessage;

  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  /// True when the account lives in Firebase rather than on this device.
  bool get isCloud => _auth.isCloud;

  String get displayName {
    final name = _auth.currentUser?.displayName ?? '';
    return name.isEmpty ? 'Reader' : name;
  }

  String get email => _auth.currentUser?.email ?? '';
  String get initial => displayName[0].toUpperCase();

  Future<void> signOut() => _auth.signOut();

  /// Returns true once the account and its scores are gone. The router's auth
  /// redirect takes it from there and shows the login screen.
  Future<bool> deleteAccount(String password) async {
    _isDeleting = true;
    _errorMessage = null;
    _notify();
    try {
      await _auth.deleteAccount(password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('Delete account failed: $e');
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isDeleting = false;
      _notify();
    }
    return false;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  /// A successful deletion signs the reader out, which disposes this screen
  /// while `deleteAccount` is still tidying up.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_notify);
    super.dispose();
  }
}

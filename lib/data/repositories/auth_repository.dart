import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/app_user.dart';
import '../services/auth_service.dart';

/// Single source of truth for who is signed in. The router listens to this
/// to redirect between the login screens and the app.
class AuthRepository extends ChangeNotifier {
  AuthRepository({required AuthService service}) : _service = service {
    _subscription = _service.userChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  final AuthService _service;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _initialized = false;

  AppUser? get currentUser => _user;
  bool get isSignedIn => _user != null;
  bool get isInitialized => _initialized;
  bool get isCloud => _service.isCloud;

  Future<void> signIn({required String email, required String password}) async {
    _setUser(await _service.signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setUser(await _service.signUp(name: name, email: email, password: password));
  }

  Future<void> sendPasswordReset(String email) => _service.sendPasswordReset(email);

  Future<void> signOut() async {
    await _service.signOut();
    _setUser(null);
  }

  void _setUser(AppUser? user) {
    _user = user;
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

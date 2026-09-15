import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_user.dart';
import 'auth_service.dart';

/// Offline demo accounts stored on this device only.
///
/// Used while Firebase is not configured. Passwords are salted and hashed,
/// but this is NOT a substitute for real authentication.
class LocalAuthService implements AuthService {
  static const _usersKey = 'red.local.users';
  static const _sessionKey = 'red.local.session';

  final _changes = StreamController<AppUser?>.broadcast();

  @override
  bool get isCloud => false;

  @override
  Stream<AppUser?> userChanges() async* {
    yield await _currentUser();
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final users = await _loadUsers();
    final record = users[_key(email)];
    if (record == null || record['hash'] != _hash(record['salt'] as String, password)) {
      throw const AuthException('The email or password is not correct.');
    }
    final user = _toAppUser(record);
    await _setSession(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    if (users.containsKey(_key(email))) {
      throw const AuthException('An account with this email already exists.');
    }
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final record = {
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'name': name.trim(),
      'email': email.trim(),
      'salt': salt,
      'hash': _hash(salt, password),
    };
    users[_key(email)] = record;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
    final user = _toAppUser(record);
    await _setSession(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthException(
      'Password reset needs an internet account. In demo mode, create a new account instead.',
    );
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _changes.add(null);
  }

  Future<AppUser?> _currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    final record = (await _loadUsers())[email];
    return record == null ? null : _toAppUser(record);
  }

  Future<void> _setSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, _key(user.email));
    _changes.add(user);
  }

  Future<Map<String, Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  }

  String _key(String email) => email.trim().toLowerCase();

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  AppUser _toAppUser(Map<String, dynamic> r) => AppUser(
    id: r['id'] as String,
    displayName: r['name'] as String,
    email: r['email'] as String,
  );
}

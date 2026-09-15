import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/attempt.dart';

abstract interface class ProgressService {
  /// Newest first.
  Future<List<Attempt>> fetchAttempts(String userId);

  Future<void> addAttempt(String userId, Attempt attempt);
}

/// Stores attempts at `users/{uid}/attempts/{attemptId}`.
class FirestoreProgressService implements ProgressService {
  FirestoreProgressService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _attempts(String userId) =>
      _firestore.collection('users').doc(userId).collection('attempts');

  @override
  Future<List<Attempt>> fetchAttempts(String userId) async {
    final snapshot = await _attempts(userId)
        .orderBy('completedAt', descending: true)
        .limit(500)
        .get();
    return snapshot.docs.map((d) => Attempt.fromJson(d.data())).toList();
  }

  @override
  Future<void> addAttempt(String userId, Attempt attempt) => _attempts(userId)
      .doc(attempt.id)
      .set({...attempt.toJson(), 'savedAt': FieldValue.serverTimestamp()});
}

/// Offline demo storage on this device.
class LocalProgressService implements ProgressService {
  String _key(String userId) => 'red.attempts.$userId';

  @override
  Future<List<Attempt>> fetchAttempts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Attempt.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  @override
  Future<void> addAttempt(String userId, Attempt attempt) async {
    final existing = await fetchAttempts(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode([attempt.toJson(), ...existing.map((a) => a.toJson())]),
    );
  }
}

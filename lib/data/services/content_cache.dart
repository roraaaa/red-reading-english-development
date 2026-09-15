import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/content_snapshot.dart';

/// Keeps the last content downloaded from the cloud on the device, so new
/// stories are available offline and on the next launch.
class ContentCache {
  static const _key = 'red.content.snapshot';

  Future<ContentSnapshot?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return ContentSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ignoring unreadable content cache: $e');
      return null;
    }
  }

  Future<void> write(ContentSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

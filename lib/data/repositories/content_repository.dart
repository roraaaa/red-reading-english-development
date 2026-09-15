import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/models/content_snapshot.dart';
import '../../domain/models/passage.dart';
import '../../domain/use_cases/content_validator.dart';
import '../services/content_cache.dart';
import '../services/content_service.dart';

/// Single source of truth for reading content.
///
/// Starts with the newest content already on the device (cloud cache, or the
/// copy bundled with the app), then checks the cloud for newer content and
/// notifies listeners when it switches over.
class ContentRepository extends ChangeNotifier {
  ContentRepository({
    required ContentSource bundled,
    required ContentCache cache,
    CloudContentSource? cloud,
    Random? random,
    DateTime Function()? clock,
    this.minCheckInterval = const Duration(minutes: 5),
  }) : _bundled = bundled,
       _cache = cache,
       _cloud = cloud,
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  final ContentSource _bundled;
  final ContentCache _cache;
  final CloudContentSource? _cloud;
  final Random _random;
  final DateTime Function() _clock;

  /// How long to wait between cloud checks (each check is one small read).
  final Duration minCheckInterval;

  ContentSnapshot _content = const ContentSnapshot(version: 0, levels: [], passages: []);
  bool _isRefreshing = false;
  DateTime? _lastCheck;

  int get version => _content.version;
  List<ReadingLevel> get levels => _content.levels;
  bool get isRefreshing => _isRefreshing;

  Future<void> load() async {
    final bundled = await _bundled.load();
    final cached = await _cache.read();
    final useCache =
        cached != null && cached.version > bundled.version && ContentValidator.validate(cached).isEmpty;
    _apply(useCache ? cached : bundled);
  }

  /// Downloads newer content if some has been published. Returns true when
  /// the content changed. Never throws: problems keep the current content.
  Future<bool> refreshFromCloud({bool force = false}) async {
    final cloud = _cloud;
    if (cloud == null || _isRefreshing) return false;
    final now = _clock();
    if (!force && _lastCheck != null && now.difference(_lastCheck!) < minCheckInterval) return false;

    _isRefreshing = true;
    _lastCheck = now;
    try {
      final remoteVersion = await cloud.fetchVersion();
      if (remoteVersion == null || remoteVersion <= _content.version) return false;

      final snapshot = await cloud.fetchSnapshot();
      final problems = ContentValidator.validate(snapshot);
      if (problems.isNotEmpty) {
        debugPrint('Published content has problems, keeping current content:\n${problems.join('\n')}');
        return false;
      }
      await _cache.write(snapshot);
      _apply(snapshot);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Could not check for new content: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _apply(ContentSnapshot snapshot) {
    _content = ContentSnapshot(
      version: snapshot.version,
      levels: [...snapshot.levels]..sort((a, b) => a.number.compareTo(b.number)),
      passages: [...snapshot.passages]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  ReadingLevel? level(String id) {
    for (final l in _content.levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Passage> materialsFor(String levelId) =>
      _content.passages.where((p) => p.levelId == levelId).toList();

  Passage? material(String id) {
    for (final p in _content.passages) {
      if (p.id == id && p.levelId != null) return p;
    }
    return null;
  }

  Passage? assessment(String id) {
    for (final p in _content.passages) {
      if (p.id == id && p.difficulty != null) return p;
    }
    return null;
  }

  int assessmentCount(Difficulty difficulty) =>
      _content.passages.where((p) => p.difficulty == difficulty).length;

  /// A random card of the given difficulty, avoiding [recentIds] when possible
  /// so the child does not get the same card twice in a row.
  Passage randomAssessment(Difficulty difficulty, {Set<String> recentIds = const {}}) {
    final pool = _content.passages.where((p) => p.difficulty == difficulty).toList();
    if (pool.isEmpty) {
      throw StateError('No assessment cards for ${difficulty.name}');
    }
    final fresh = pool.where((p) => !recentIds.contains(p.id)).toList();
    final choices = fresh.isEmpty ? pool : fresh;
    return choices[_random.nextInt(choices.length)];
  }
}

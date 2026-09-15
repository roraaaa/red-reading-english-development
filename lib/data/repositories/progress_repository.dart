import 'package:flutter/foundation.dart';

import '../../domain/models/attempt.dart';
import '../services/progress_service.dart';
import 'auth_repository.dart';

/// Scores for the signed-in user, cached in memory and reloaded when the
/// user changes.
class ProgressRepository extends ChangeNotifier {
  ProgressRepository({
    required AuthRepository auth,
    required ProgressService service,
  }) : _auth = auth,
       _service = service {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthRepository _auth;
  final ProgressService _service;

  String? _loadedFor;
  List<Attempt> _attempts = const [];
  bool _isLoading = false;
  Object? _error;

  List<Attempt> get attempts => _attempts;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  List<Attempt> get assessments =>
      _attempts.where((a) => a.kind == AttemptKind.assessment).toList();

  List<Attempt> get materialAttempts =>
      _attempts.where((a) => a.kind == AttemptKind.material).toList();

  void _onAuthChanged() {
    final uid = _auth.currentUser?.id;
    if (uid == _loadedFor) return;
    _loadedFor = uid;
    _attempts = const [];
    _error = null;
    notifyListeners();
    if (uid != null) refresh();
  }

  Future<void> refresh() async {
    final uid = _loadedFor;
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await _service.fetchAttempts(uid);
      if (uid != _loadedFor) return;
      _attempts = loaded;
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(Attempt attempt) async {
    final uid = _loadedFor;
    if (uid == null) throw StateError('Cannot save progress when signed out');
    await _service.addAttempt(uid, attempt);
    _attempts = [attempt, ..._attempts];
    notifyListeners();
  }

  int bestStarsFor(String passageId) {
    var best = 0;
    for (final a in _attempts) {
      if (a.kind == AttemptKind.material && a.passageId == passageId && a.stars > best) {
        best = a.stars;
      }
    }
    return best;
  }

  bool hasCompleted(String passageId) =>
      _attempts.any((a) => a.kind == AttemptKind.material && a.passageId == passageId);

  /// Sum of the best stars for every material story.
  int get totalMaterialStars {
    final best = <String, int>{};
    for (final a in materialAttempts) {
      if (a.stars > (best[a.passageId] ?? -1)) best[a.passageId] = a.stars;
    }
    return best.values.fold(0, (sum, s) => sum + s);
  }

  int get storiesCompleted => materialAttempts.map((a) => a.passageId).toSet().length;

  Set<String> get recentAssessmentIds =>
      assessments.take(3).map((a) => a.passageId).toSet();

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

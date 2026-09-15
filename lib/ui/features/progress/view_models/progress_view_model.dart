import 'package:flutter/foundation.dart';

import '../../../../data/repositories/content_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../domain/models/attempt.dart';
import '../../../../domain/models/passage.dart';

class ProgressViewModel extends ChangeNotifier {
  ProgressViewModel({required ProgressRepository progress, required ContentRepository content})
    : _progress = progress,
      _content = content {
    _progress.addListener(notifyListeners);
    _content.addListener(notifyListeners);
  }

  final ProgressRepository _progress;
  final ContentRepository _content;

  bool get isLoading => _progress.isLoading;
  bool get hasError => _progress.error != null;
  List<Attempt> get attempts => _progress.attempts;

  int get totalStars => _progress.totalMaterialStars;
  int get storiesCompleted => _progress.storiesCompleted;
  int get totalStories =>
      _content.levels.fold(0, (sum, l) => sum + _content.materialsFor(l.id).length);
  int get assessmentsTaken => _progress.assessments.length;

  /// Average assessment score as a percentage, or null if none taken.
  int? get averageAssessmentPercent {
    final list = _progress.assessments;
    if (list.isEmpty) return null;
    final avg = list.fold(0.0, (sum, a) => sum + a.ratio) / list.length;
    return (avg * 100).round();
  }

  int? get bestWordsPerMinute {
    final speeds = _progress.assessments.map((a) => a.wordsPerMinute).whereType<int>();
    return speeds.isEmpty ? null : speeds.reduce((a, b) => a > b ? a : b);
  }

  ReadingLevel? levelFor(Attempt attempt) =>
      attempt.levelId == null ? null : _content.level(attempt.levelId!);

  /// Pull-to-refresh reloads scores and checks for newly published stories.
  Future<void> refresh() async {
    await Future.wait([_progress.refresh(), _content.refreshFromCloud(force: true)]);
  }

  @override
  void dispose() {
    _progress.removeListener(notifyListeners);
    _content.removeListener(notifyListeners);
    super.dispose();
  }
}

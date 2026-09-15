import 'package:flutter/foundation.dart';

import '../../../../data/repositories/content_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../domain/models/passage.dart';

class LevelSummary {
  const LevelSummary({
    required this.level,
    required this.storyCount,
    required this.completed,
    required this.stars,
  });

  final ReadingLevel level;
  final int storyCount;
  final int completed;
  final int stars;

  int get maxStars => storyCount * 3;
  double get fraction => storyCount == 0 ? 0 : completed / storyCount;
}

class LevelsViewModel extends ChangeNotifier {
  LevelsViewModel({required ContentRepository content, required ProgressRepository progress})
    : _content = content,
      _progress = progress {
    _content.addListener(notifyListeners);
    _progress.addListener(notifyListeners);
  }

  final ContentRepository _content;
  final ProgressRepository _progress;

  List<LevelSummary> get levels => [
    for (final level in _content.levels) _summaryFor(level),
  ];

  LevelSummary _summaryFor(ReadingLevel level) {
    final stories = _content.materialsFor(level.id);
    return LevelSummary(
      level: level,
      storyCount: stories.length,
      completed: stories.where((s) => _progress.hasCompleted(s.id)).length,
      stars: stories.fold(0, (sum, s) => sum + _progress.bestStarsFor(s.id)),
    );
  }

  @override
  void dispose() {
    _content.removeListener(notifyListeners);
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}

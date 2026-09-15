import 'package:flutter/foundation.dart';

import '../../../../data/repositories/content_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../domain/models/passage.dart';

class StoryItem {
  const StoryItem({required this.passage, required this.bestStars, required this.completed});

  final Passage passage;
  final int bestStars;
  final bool completed;
}

class StoriesViewModel extends ChangeNotifier {
  StoriesViewModel({
    required String levelId,
    required ContentRepository content,
    required ProgressRepository progress,
  }) : _levelId = levelId,
       _content = content,
       _progress = progress {
    _content.addListener(notifyListeners);
    _progress.addListener(notifyListeners);
  }

  final String _levelId;
  final ContentRepository _content;
  final ProgressRepository _progress;

  ReadingLevel? get level => _content.level(_levelId);

  List<StoryItem> get stories => [
    for (final p in _content.materialsFor(_levelId))
      StoryItem(passage: p, bestStars: _progress.bestStarsFor(p.id), completed: _progress.hasCompleted(p.id)),
  ];

  int get completedCount => stories.where((s) => s.completed).length;

  @override
  void dispose() {
    _content.removeListener(notifyListeners);
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}

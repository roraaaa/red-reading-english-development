import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/story_cover.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/stories_view_model.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, required this.levelId});

  final String levelId;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late final StoriesViewModel _viewModel = StoriesViewModel(
    levelId: widget.levelId,
    content: context.read(),
    progress: context.read(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _viewModel.level;
    if (level == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('That level could not be found.')));
    }
    final color = Color(level.colorValue);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Level ${level.number}')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final stories = _viewModel.stories;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                ContentWidth(
                  maxWidth: 820,
                  child: FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: color.tint, borderRadius: BorderRadius.circular(26)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text('${level.name} stories', style: AppTheme.display(size: 26, color: color.deep)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_viewModel.completedCount} of ${stories.length} stories done',
                                  style: AppTheme.body(size: 14, color: AppColors.inkSoft),
                                ),
                                const SizedBox(height: 12),
                                ChunkyProgressBar(
                                  value: stories.isEmpty ? 0 : _viewModel.completedCount / stories.length,
                                  color: color,
                                  semanticsLabel: 'Level progress',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(AppIcons.of(level.icon), size: 56, color: color),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ContentWidth(
                  maxWidth: 820,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 640 ? 2 : 1;
                      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final (i, item) in stories.indexed)
                            SizedBox(
                              width: width,
                              child: FadeSlideIn(
                                delay: Duration(milliseconds: 100 + i * 80),
                                child: _StoryCard(
                                  item: item,
                                  color: color,
                                  onTap: () => context.push(Routes.story(level.id, item.passage.id)),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.item, required this.color, required this.onTap});

  final StoryItem item;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final passage = item.passage;
    return Semantics(
      button: true,
      label:
          '${passage.title}. ${passage.topic}. ${passage.questions.length} questions. '
          '${item.completed ? 'Best score ${item.bestStars} of 3 stars.' : 'Not read yet.'}',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outline, width: 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: StoryCover(passage: passage, color: color, height: 84, radius: 18, iconSize: 40),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passage.topic.toUpperCase(),
                            style: AppTheme.body(size: 11, color: color.deep, weight: FontWeight.w700).copyWith(letterSpacing: 0.8)),
                        Text(passage.title, style: AppTheme.display(size: 18, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (item.completed)
                              StarRow(stars: item.bestStars, size: 20)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.sunshine, borderRadius: BorderRadius.circular(10)),
                                child: Text('NEW', style: AppTheme.body(size: 11, weight: FontWeight.w700)),
                              ),
                            const Spacer(),
                            Text('${passage.wordCount} words',
                                style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

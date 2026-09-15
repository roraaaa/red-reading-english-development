import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/levels_view_model.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late final LevelsViewModel _viewModel = LevelsViewModel(content: context.read(), progress: context.read());

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Materials')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final levels = _viewModel.levels;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                ContentWidth(
                  child: FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text('Pick your level', style: AppTheme.display(size: 28))),
                        const SizedBox(height: 4),
                        Text(
                          'Start with Green and climb all the way to Pink!',
                          style: AppTheme.body(color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final (i, summary) in levels.indexed)
                  ContentWidth(
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 80 + i * 80),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _LevelCard(
                          summary: summary,
                          onTap: () => context.push(Routes.level(summary.level.id)),
                        ),
                      ),
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.summary, required this.onTap});

  final LevelSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = summary.level;
    final color = Color(level.colorValue);
    return Semantics(
      button: true,
      label:
          'Level ${level.number}, ${level.name}. ${level.description}. '
          '${summary.completed} of ${summary.storyCount} stories done, ${summary.stars} stars.',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: color.tint,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.45), width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(color, Colors.white, 0.2)!, color.edge],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.of(level.icon), color: Colors.white, size: 30),
                        Text(
                          'Level ${level.number}',
                          style: AppTheme.body(size: 11, color: Colors.white, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.name, style: AppTheme.display(size: 24, color: color.deep)),
                        Text(level.description, style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: ChunkyProgressBar(value: summary.fraction, color: color, height: 8)),
                            const SizedBox(width: 10),
                            const Icon(Icons.star_rounded, size: 18, color: AppColors.sunshineDeep),
                            const SizedBox(width: 2),
                            Text(
                              '${summary.stars}/${summary.maxStars}',
                              style: AppTheme.body(size: 13, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: color.deep),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

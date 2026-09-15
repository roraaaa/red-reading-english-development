import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/attempt.dart';
import '../../../../domain/models/passage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/progress_view_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressViewModel _viewModel = ProgressViewModel(progress: context.read(), content: context.read());

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('My progress')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                ContentWidth(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _SummaryGrid(viewModel: _viewModel)),
                      const SizedBox(height: 24),
                      Semantics(header: true, child: Text('Recent activity', style: AppTheme.display(size: 22))),
                      const SizedBox(height: 10),
                      if (_viewModel.isLoading && _viewModel.attempts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_viewModel.hasError && _viewModel.attempts.isEmpty)
                        _Message(
                          icon: Icons.cloud_off_rounded,
                          text: 'We could not load your scores. Pull down to try again.',
                        )
                      else if (_viewModel.attempts.isEmpty)
                        const _EmptyState()
                      else
                        for (final (i, attempt) in _viewModel.attempts.take(50).indexed)
                          FadeSlideIn(
                            delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                            child: _AttemptTile(attempt: attempt, level: _viewModel.levelFor(attempt)),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.viewModel});

  final ProgressViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _SummaryTile(icon: Icons.star_rounded, color: AppColors.sunshineDeep, value: '${viewModel.totalStars}', label: 'Stars earned'),
      _SummaryTile(
        icon: Icons.menu_book_rounded,
        color: AppColors.leaf,
        value: '${viewModel.storiesCompleted}/${viewModel.totalStories}',
        label: 'Stories read',
      ),
      _SummaryTile(icon: Icons.timer_rounded, color: AppColors.primary, value: '${viewModel.assessmentsTaken}', label: 'Tests taken'),
      _SummaryTile(
        icon: Icons.insights_rounded,
        color: AppColors.materialsEnd,
        value: viewModel.averageAssessmentPercent == null ? '-' : '${viewModel.averageAssessmentPercent}%',
        label: 'Average test score',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(value, style: AppTheme.display(size: 26)),
            Text(label, style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt, required this.level});

  final Attempt attempt;
  final ReadingLevel? level;

  @override
  Widget build(BuildContext context) {
    final isAssessment = attempt.kind == AttemptKind.assessment;
    final color = isAssessment ? AppColors.primary : Color(level?.colorValue ?? AppColors.leaf.toARGB32());
    final date = DateFormat.yMMMd().add_jm().format(attempt.completedAt);
    final subtitle = isAssessment
        ? 'Assessment · ${Difficulty.fromName(attempt.difficulty)?.label ?? ''}'
            '${attempt.wordsPerMinute == null ? '' : ' · ${attempt.wordsPerMinute} wpm'}'
        : 'Level ${level?.number ?? ''} ${level?.name ?? ''}';

    return Semantics(
      label: '${attempt.passageTitle}. $subtitle. ${attempt.correct} of ${attempt.total} correct. $date.',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(isAssessment ? Icons.timer_rounded : Icons.auto_stories_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attempt.passageTitle, style: AppTheme.body(weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
                  Text(date, style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StarRow(stars: attempt.stars, size: 16),
                Text('${attempt.correct}/${attempt.total}', style: AppTheme.display(size: 18, weight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Floating(child: RedPandaLogo(size: 110, semanticLabel: null)),
          const SizedBox(height: 12),
          Text('No scores yet', style: AppTheme.display(size: 22)),
          const SizedBox(height: 4),
          Text(
            'Read a story in Materials or take an assessment, and your scores will show up here.',
            textAlign: TextAlign.center,
            style: AppTheme.body(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(icon, size: 40, color: AppColors.inkSoft),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: AppTheme.body(color: AppColors.inkSoft)),
      ],
    ),
  );
}

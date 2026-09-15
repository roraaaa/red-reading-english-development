import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/reading_result.dart';
import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/star_row.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/reading_session_view_model.dart';
import 'pdf_actions.dart';

class ResultsView extends StatelessWidget {
  const ResultsView({super.key, required this.viewModel});

  final ReadingSessionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final result = viewModel.result!;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: ContentWidth(
                  maxWidth: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _ScoreHeader(result: result)),
                      const SizedBox(height: 12),
                      _SaveStatus(viewModel: viewModel),
                      if (result.isAssessment) ...[
                        const SizedBox(height: 12),
                        FadeSlideIn(delay: const Duration(milliseconds: 150), child: _AssessmentStats(result: result)),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfActions.saveResult(context, result),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Save results as PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDeep,
                            minimumSize: const Size(48, 48),
                            side: const BorderSide(color: AppColors.outline, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Your answers'),
                      for (final (i, q) in result.passage.questions.indexed)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 200 + i * 60),
                          child: _AnswerTile(
                            number: i + 1,
                            prompt: q.prompt,
                            response: result.responses[q.id] ?? '',
                            correctAnswer: q.correctAnswerLabel,
                            isCorrect: result.correctById[q.id] ?? false,
                          ),
                        ),
                      const SizedBox(height: 20),
                      _SectionTitle('Tips for you'),
                      _Advice(result: result),
                      const SizedBox(height: 20),
                      _SectionTitle('Skills'),
                      SoftCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            for (final s in result.skillBreakdown)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(flex: 5, child: Text(s.skill.label, style: AppTheme.body(size: 14, weight: FontWeight.w500))),
                                    Expanded(
                                      flex: 4,
                                      child: ChunkyProgressBar(
                                        value: s.total == 0 ? 0 : s.correct / s.total,
                                        color: s.correct == s.total ? AppColors.correct : AppColors.sunshineDeep,
                                        height: 10,
                                        semanticsLabel: s.skill.label,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('${s.correct}/${s.total}', style: AppTheme.body(size: 14, weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                boxShadow: [BoxShadow(color: Color(0x142A2340), blurRadius: 20, offset: Offset(0, -6))],
              ),
              child: ContentWidth(
                maxWidth: 640,
                child: Row(
                  children: [
                    if (!result.isAssessment) ...[
                      Expanded(
                        child: ChunkyButton(
                          label: 'Retry',
                          icon: Icons.replay_rounded,
                          variant: ChunkyVariant.secondary,
                          onPressed: viewModel.isSaving ? null : viewModel.retry,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ChunkyButton(
                        label: 'Finish',
                        icon: Icons.home_rounded,
                        onPressed: () => result.isAssessment ? context.go(Routes.home) : context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(header: true, child: Text(text, style: AppTheme.display(size: 22))),
  );
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (result.stars) {
      3 => ('Amazing!', 'You are a super reader!'),
      2 => ('Great job!', 'You understood most of the story.'),
      1 => ('Good try!', 'Every story makes you a stronger reader.'),
      _ => ('Keep practicing!', "Don't give up. Let's learn from the tips below."),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE8B8), Color(0xFFFFF4DD)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          StarRow(stars: result.stars, size: 64, animate: true, emptyColor: const Color(0xFFF1D9A6)),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(title, style: AppTheme.display(size: 32, color: const Color(0xFF5A3A00))),
          ),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: AppTheme.body(color: const Color(0xFF5A3A00))),
          const SizedBox(height: 16),
          Row(
            children: [
              const PopIn(delay: Duration(milliseconds: 900), child: RedPandaLogo(size: 64, semanticLabel: null)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.correct} of ${result.total} correct',
                      style: AppTheme.display(size: 22, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ChunkyProgressBar(
                      value: result.total == 0 ? 0 : result.correct / result.total,
                      color: AppColors.leaf,
                      semanticsLabel: 'Reading comprehension',
                    ),
                    const SizedBox(height: 4),
                    Text('Reading comprehension', style: AppTheme.body(size: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentStats extends StatelessWidget {
  const _AssessmentStats({required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context) {
    final seconds = result.readingTime!.inMilliseconds / 1000;
    final timeLabel = seconds >= 60
        ? '${seconds ~/ 60}m ${(seconds % 60).round()}s'
        : '${seconds.toStringAsFixed(1)}s';
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _Stat(icon: Icons.timer_rounded, color: AppColors.primary, value: timeLabel, label: 'Reading time')),
              Expanded(
                child: _Stat(
                  icon: Icons.speed_rounded,
                  color: AppColors.materialsEnd,
                  value: '${result.wordsPerMinute}',
                  label: 'Words per minute',
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.directions_run_rounded,
                  color: AppColors.leaf,
                  value: result.speed!.label.split(' ').first,
                  label: 'Pace',
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.outline),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.sunshineDeep),
              const SizedBox(width: 10),
              Expanded(child: Text(result.verdict!, style: AppTheme.body(weight: FontWeight.w600))),
            ],
          ),
          if (result.leftAppCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              'You left the app ${result.leftAppCount} time${result.leftAppCount == 1 ? '' : 's'} while reading, '
              'so your reading time may not be exact.',
              style: AppTheme.body(size: 13, color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.display(size: 20, weight: FontWeight.w600)),
          Text(label, textAlign: TextAlign.center, style: AppTheme.body(size: 11, color: AppColors.inkSoft, height: 1.2)),
        ],
      ),
    );
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.viewModel});

  final ReadingSessionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (viewModel.isSaving) {
      child = Row(
        key: const ValueKey('saving'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Saving your score...', style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
        ],
      );
    } else if (viewModel.saveError != null) {
      child = Container(
        key: const ValueKey('error'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.wrongTint, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.wrong),
            const SizedBox(width: 8),
            Expanded(child: Text(viewModel.saveError!, style: AppTheme.body(size: 13, color: AppColors.wrong))),
            TextButton(onPressed: viewModel.saveResult, child: const Text('Try again')),
          ],
        ),
      );
    } else if (viewModel.isSaved) {
      child = Row(
        key: const ValueKey('saved'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_done_rounded, size: 18, color: AppColors.correct),
          const SizedBox(width: 6),
          Text('Score saved to your account', style: AppTheme.body(size: 13, color: AppColors.correct)),
        ],
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.number,
    required this.prompt,
    required this.response,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final int number;
  final String prompt;
  final String response;
  final String correctAnswer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.correct : AppColors.wrong;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: isCorrect ? AppColors.correctTint : AppColors.wrongTint, shape: BoxShape.circle),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: color,
              size: 22,
              semanticLabel: isCorrect ? 'Correct' : 'Not correct',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. $prompt', style: AppTheme.body(weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Your answer: ', style: AppTheme.body(size: 14, color: AppColors.inkSoft)),
                      TextSpan(
                        text: response.isEmpty ? '(no answer)' : response,
                        style: AppTheme.body(size: 14, color: color, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (!isCorrect)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Correct answer: ', style: AppTheme.body(size: 14, color: AppColors.inkSoft)),
                        TextSpan(text: correctAnswer, style: AppTheme.body(size: 14, color: AppColors.correct, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context) {
    if (result.skillsToPractice.isEmpty) {
      return SoftCard(
        color: AppColors.correctTint,
        borderColor: AppColors.correctTint,
        child: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: AppColors.correct, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Perfect score! Keep reading a little every day and try a harder level next.',
                style: AppTheme.body(color: AppColors.leafDeep, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final skill in result.skillsToPractice)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFF9EC),
              borderColor: const Color(0xFFF6E3B4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.sunshineDeep, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill.adviceTitle, style: AppTheme.display(size: 18, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(skill.advice, style: AppTheme.body(size: 14, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

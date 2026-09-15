import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/passage.dart';
import '../../../../routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/red_panda_logo.dart';
import '../../../core/widgets/surfaces.dart';

class AssessIntroScreen extends StatefulWidget {
  const AssessIntroScreen({super.key});

  @override
  State<AssessIntroScreen> createState() => _AssessIntroScreenState();
}

class _AssessIntroScreenState extends State<AssessIntroScreen> {
  Difficulty _difficulty = Difficulty.easy;

  Future<void> _start() async {
    final ready = await showDialog<bool>(
      context: context,
      builder: (context) => const _TimerNoticeDialog(),
    );
    if (ready == true && mounted) {
      context.push(Routes.assessSession(_difficulty));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Assessment')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FadeSlideIn(child: _SpeechBubbleIntro()),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Semantics(header: true, child: Text('How it works', style: AppTheme.display(size: 20))),
                      ),
                      const SizedBox(height: 12),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 160),
                        child: SoftCard(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _Step(number: 1, icon: Icons.menu_book_rounded, text: 'Read a surprise story. A quiet timer keeps track of your reading time.'),
                              _Step(number: 2, icon: Icons.quiz_rounded, text: 'Answer questions about it. No peeking back at the story!'),
                              _Step(number: 3, icon: Icons.emoji_events_rounded, text: 'See your score, your reading speed and tips to get even better.', isLast: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 220),
                        child: Semantics(header: true, child: Text('Choose a difficulty', style: AppTheme.display(size: 20))),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, d) in Difficulty.values.indexed)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 280 + i * 70),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DifficultyTile(
                              difficulty: d,
                              selected: d == _difficulty,
                              onTap: () => setState(() => _difficulty = d),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.leafTint, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppColors.leafDeep),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Do your own best reading, with no help. Honest answers give you the most helpful tips!',
                                style: AppTheme.body(size: 14, color: AppColors.leafDeep),
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
            _BottomBar(
              child: ChunkyButton(label: 'Start reading', icon: Icons.play_arrow_rounded, onPressed: _start),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubbleIntro extends StatelessWidget {
  const _SpeechBubbleIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Floating(child: RedPandaLogo(size: 96, semanticLabel: null)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [BoxShadow(color: Color(0x142A2340), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Text(
              "Let's see how well you read! I'll pick a story just for you.",
              style: AppTheme.body(size: 16, weight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.icon, required this.text, this.isLast = false});

  final int number;
  final IconData icon;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primaryDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('$number. $text', style: AppTheme.body(size: 15)),
          ),
        ],
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({required this.difficulty, required this.selected, required this.onTap});

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  static const _colors = {
    Difficulty.easy: AppColors.leaf,
    Difficulty.medium: AppColors.sunshineDeep,
    Difficulty.hard: AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[difficulty]!;
    final level = difficulty.index + 1;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${difficulty.label}. ${difficulty.description}',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? color : AppColors.outline, width: selected ? 2.5 : 1.5),
              ),
              child: Row(
                children: [
                  // Signal-strength style bars: 1, 2 or 3 filled.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: 8,
                          height: 12.0 + i * 8,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: i < level ? color : AppColors.outline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(difficulty.label, style: AppTheme.display(size: 19, weight: FontWeight.w600)),
                        Text(difficulty.description, style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                    child: selected
                        ? Icon(Icons.check_circle_rounded, key: const ValueKey('on'), color: color, size: 28)
                        : const Icon(Icons.circle_outlined, key: ValueKey('off'), color: AppColors.outline, size: 28),
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

class _TimerNoticeDialog extends StatelessWidget {
  const _TimerNoticeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopIn(child: RedPandaLogo(size: 90, semanticLabel: null)),
            const SizedBox(height: 8),
            Text('Ready, set, read!', style: AppTheme.display(size: 26), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your reading will be timed until you tap "I\'m done reading". Take your time and read carefully.',
              style: AppTheme.body(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ChunkyButton(label: "Let's go!", icon: Icons.timer_rounded, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 6),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: Color(0x142A2340), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: ContentWidth(child: child),
    );
  }
}

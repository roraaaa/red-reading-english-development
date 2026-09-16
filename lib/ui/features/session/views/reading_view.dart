import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/speech_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/story_cover.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/read_aloud_controller.dart';
import '../view_models/reading_session_view_model.dart';
import 'pdf_actions.dart';
import 'speakable_paragraph.dart';

class ReadingView extends StatefulWidget {
  const ReadingView({super.key, required this.viewModel});

  final ReadingSessionViewModel viewModel;

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  static const _minFont = 16.0;
  static const _maxFont = 26.0;

  final _scroll = ScrollController();
  final _scrollProgress = ValueNotifier<double>(0);
  double _fontSize = 19;

  late final ReadAloudController _readAloud = ReadAloudController(
    speech: context.read<SpeechService>(),
    paragraphs: _vm.passage!.paragraphs,
  );
  late final List<GlobalKey> _paragraphKeys = List.generate(_vm.passage!.paragraphs.length, (_) => GlobalKey());
  late final AppLifecycleListener _lifecycle;
  int? _followedParagraph;

  ReadingSessionViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _readAloud.addListener(_followReading);
    _lifecycle = AppLifecycleListener(onHide: () => _readAloud.pause());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.startReading();
      _onScroll();
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scrollProgress.value = max <= 0 ? 1 : (_scroll.offset / max).clamp(0, 1);
  }

  /// Keeps the paragraph being read aloud on screen.
  void _followReading() {
    final paragraph = _readAloud.activeParagraph;
    if (paragraph == null) {
      // Stopped: scroll to the first paragraph again next time.
      _followedParagraph = null;
      return;
    }
    if (!_readAloud.isPlaying || paragraph == _followedParagraph) return;
    _followedParagraph = paragraph;
    final target = _paragraphKeys[paragraph].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.15,
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishReading() {
    _readAloud.stop();
    _vm.finishReading();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _readAloud.removeListener(_followReading);
    _readAloud.dispose();
    _scroll.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passage = _vm.passage!;
    final level = _vm.level;
    final color = Color(passage.colorValue ?? level?.colorValue ?? AppColors.primary.toARGB32());
    final levelLabel = level == null ? null : 'Level ${level.number} ${level.name}';

    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: _scrollProgress,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 4,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
            semanticsLabel: 'Reading progress',
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: ContentWidth(
                maxWidth: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(child: StoryCover(passage: passage, color: color, height: 190)),
                    if (passage.imageCredit case final credit?) PhotoCredit(credit: credit),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Chip(label: passage.topic, color: color),
                          if (_vm.isAssessment) const _TimerChip(),
                          Text(
                            '${passage.wordCount} words  |  ${passage.questions.length} questions',
                            style: AppTheme.body(size: 13, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Semantics(header: true, child: Text(passage.title, style: AppTheme.display(size: 30))),
                    ),
                    const SizedBox(height: 14),
                    ListenableBuilder(
                      listenable: _readAloud,
                      builder: (context, _) => _ReadAloudBar(
                        controller: _readAloud,
                        fullReadAloud: !_vm.isAssessment,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReaderToolbar(
                      canShrink: _fontSize > _minFont,
                      canGrow: _fontSize < _maxFont,
                      onShrink: () => setState(() => _fontSize -= 1.5),
                      onGrow: () => setState(() => _fontSize += 1.5),
                      onPrint: _vm.isAssessment ? null : () => PdfActions.printPassage(context, passage, levelLabel: levelLabel),
                      onSave: _vm.isAssessment ? null : () => PdfActions.savePassage(context, passage, levelLabel: levelLabel),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: SoftCard(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
                        child: ListenableBuilder(
                          listenable: _readAloud,
                          builder: (context, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < _readAloud.paragraphs.length; i++)
                                Padding(
                                  key: _paragraphKeys[i],
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SpeakableParagraph(
                                    text: _readAloud.paragraphs[i],
                                    words: _readAloud.words[i],
                                    style: AppTheme.body(size: _fontSize, height: 1.75),
                                    highlightedWord: _readAloud.highlightedWordIn(i),
                                    isActive: _readAloud.activeParagraph == i,
                                    onWordTap: (word) => _readAloud.speakWord(i, word),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('The end', style: AppTheme.display(size: 16, color: AppColors.inkSoft, weight: FontWeight.w500)),
                    ),
                  ],
                ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Keeps Pause / Stop reachable after the story scrolls to
                // follow the voice.
                ListenableBuilder(
                  listenable: _readAloud,
                  builder: (context, _) => AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: !_vm.isAssessment && (_readAloud.isPlaying || _readAloud.canResume)
                        ? _MiniPlayer(controller: _readAloud)
                        : const SizedBox(width: double.infinity),
                  ),
                ),
                ChunkyButton(
                  label: _vm.isAssessment ? "I'm done reading" : "I'm ready for the questions",
                  icon: Icons.check_rounded,
                  onPressed: _finishReading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.controller});

  final ReadAloudController controller;

  @override
  Widget build(BuildContext context) {
    final playing = controller.isPlaying;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: playing ? 'Pause' : 'Keep listening',
            style: IconButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(44, 44)),
            onPressed: playing ? controller.pause : controller.play,
            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              playing ? 'Reading aloud...' : 'Paused',
              style: AppTheme.body(size: 14, weight: FontWeight.w600, color: AppColors.primaryDeep),
            ),
          ),
          if (playing) ...[const _SoundWave(), const SizedBox(width: 6)],
          IconButton(
            tooltip: 'Stop reading aloud',
            onPressed: controller.stop,
            icon: const Icon(Icons.stop_rounded, color: AppColors.primaryDeep),
          ),
        ],
      ),
    );
  }
}

/// Materials: a Listen / Pause button plus the tap-a-word tip.
/// Assess: only the tip, so timed reading stays fair.
class _ReadAloudBar extends StatelessWidget {
  const _ReadAloudBar({required this.controller, required this.fullReadAloud});

  final ReadAloudController controller;
  final bool fullReadAloud;

  @override
  Widget build(BuildContext context) {
    if (controller.isUnavailable) {
      return _Tip(
        icon: Icons.volume_off_rounded,
        text: "Read-aloud isn't available on this device right now.",
      );
    }

    final tip = _Tip(
      icon: Icons.touch_app_rounded,
      text: fullReadAloud ? 'Tip: tap any word to hear it.' : 'Stuck on a word? Tap it to hear how it sounds.',
    );
    if (!fullReadAloud) return tip;

    final (label, icon) = controller.isPlaying
        ? ('Pause', Icons.pause_rounded)
        : controller.canResume
        ? ('Keep listening', Icons.play_arrow_rounded)
        : ('Listen to the story', Icons.volume_up_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChunkyButton(
              label: label,
              icon: icon,
              expand: false,
              variant: ChunkyVariant.soft,
              onPressed: controller.isPlaying ? controller.pause : controller.play,
            ),
            if (controller.canResume && !controller.isPlaying) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Start from the beginning',
                onPressed: controller.stop,
                icon: const Icon(Icons.replay_rounded, color: AppColors.primaryDeep),
              ),
            ],
            if (controller.isPlaying) ...[
              const SizedBox(width: 12),
              const _SoundWave(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        tip,
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: AppTheme.body(size: 13, color: AppColors.inkSoft))),
      ],
    );
  }
}

/// Three bouncing bars shown while the story is being read aloud.
class _SoundWave extends StatefulWidget {
  const _SoundWave();

  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 5,
                height: still ? 14 : 8 + 14 * (0.5 + 0.5 * _wave(_controller.value + i * 0.3)),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
              ),
          ],
        ),
      ),
    );
  }

  double _wave(double t) {
    final x = (t % 1.0) * 2 - 1;
    return 1 - x * x * 2;
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.canShrink,
    required this.canGrow,
    required this.onShrink,
    required this.onGrow,
    this.onPrint,
    this.onSave,
  });

  final bool canShrink;
  final bool canGrow;
  final VoidCallback onShrink;
  final VoidCallback onGrow;
  final VoidCallback? onPrint;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Smaller text',
                onPressed: canShrink ? onShrink : null,
                icon: const Icon(Icons.text_decrease_rounded),
              ),
              IconButton(
                tooltip: 'Bigger text',
                onPressed: canGrow ? onGrow : null,
                icon: const Icon(Icons.text_increase_rounded),
              ),
            ],
          ),
        ),
        if (onPrint != null) _ToolButton(icon: Icons.print_rounded, label: 'Print', onPressed: onPrint!),
        if (onSave != null) _ToolButton(icon: Icons.picture_as_pdf_rounded, label: 'Save', onPressed: onSave!),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: AppTheme.body(size: 14, weight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppTheme.body(size: 13, weight: FontWeight.w600, color: HSLColor.fromColor(color).withLightness(0.28).toColor()),
      ),
    );
  }
}

/// A calm "timer is on" indicator. The time itself is hidden so readers do
/// not feel rushed.
class _TimerChip extends StatefulWidget {
  const _TimerChip();

  @override
  State<_TimerChip> createState() => _TimerChipState();
}

class _TimerChipState extends State<_TimerChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'The reading timer is on',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: reduceMotion(context) ? const AlwaysStoppedAnimation(1) : Tween(begin: 0.3, end: 1.0).animate(_pulse),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Text('Timer on', style: AppTheme.body(size: 13, weight: FontWeight.w600, color: AppColors.primaryDeep)),
          ],
        ),
      ),
    );
  }
}

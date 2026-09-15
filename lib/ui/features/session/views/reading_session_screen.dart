import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/passage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../view_models/reading_session_view_model.dart';
import 'quiz_view.dart';
import 'reading_view.dart';
import 'results_view.dart';

class ReadingSessionScreen extends StatefulWidget {
  const ReadingSessionScreen.assessment({super.key, required Difficulty this.difficulty}) : passageId = null;

  const ReadingSessionScreen.material({super.key, required String this.passageId}) : difficulty = null;

  final Difficulty? difficulty;
  final String? passageId;

  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  late final ReadingSessionViewModel _viewModel = widget.difficulty != null
      ? ReadingSessionViewModel.assessment(
          difficulty: widget.difficulty!,
          content: context.read(),
          progress: context.read(),
          grader: context.read(),
        )
      : ReadingSessionViewModel.material(
          passageId: widget.passageId!,
          content: context.read(),
          progress: context.read(),
          grader: context.read(),
        );

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => _viewModel.onAppHidden());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave this story?', style: AppTheme.display(size: 22)),
        content: Text(
          _viewModel.isAssessment
              ? 'Your assessment will not be saved if you leave now.'
              : 'Your answers will not be saved if you leave now.',
          style: AppTheme.body(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.loadError != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text(_viewModel.loadError!, style: AppTheme.body())),
      );
    }

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final phase = _viewModel.phase;
        return PopScope(
          canPop: phase == SessionPhase.results,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(switch (phase) {
                SessionPhase.reading => _viewModel.isAssessment ? 'Reading time' : _levelTitle(),
                SessionPhase.quiz => 'Questions',
                SessionPhase.results => 'Results',
              }),
            ),
            body: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (phase) {
                  SessionPhase.reading => ReadingView(key: const ValueKey('reading'), viewModel: _viewModel),
                  SessionPhase.quiz => QuizView(key: const ValueKey('quiz'), viewModel: _viewModel),
                  SessionPhase.results => ResultsView(key: const ValueKey('results'), viewModel: _viewModel),
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _levelTitle() {
    final level = _viewModel.level;
    return level == null ? 'Story' : 'Level ${level.number} · ${level.name}';
  }
}

import 'package:flutter/material.dart';

import '../../../../domain/models/question.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../view_models/reading_session_view_model.dart';

class QuizView extends StatefulWidget {
  const QuizView({super.key, required this.viewModel});

  final ReadingSessionViewModel viewModel;

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _forward = true;

  ReadingSessionViewModel get _vm => widget.viewModel;

  TextEditingController _controllerFor(Question q) =>
      _controllers.putIfAbsent(q.id, () => TextEditingController(text: _vm.responseFor(q)));

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _forward = true);
    _vm.nextQuestion();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() => _forward = false);
    _vm.previousQuestion();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final blanks = _vm.questions.length - _vm.answeredCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check my answers?', style: AppTheme.display(size: 22)),
        content: Text(
          blanks == 0
              ? 'You answered every question. Great job!'
              : 'You left $blanks question${blanks == 1 ? '' : 's'} blank. You can go back, or check your answers now.',
          style: AppTheme.body(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go back')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Check answers')),
        ],
      ),
    );
    if (confirmed == true) await _vm.submit();
  }

  void _peekAtStory() {
    final passage = _vm.passage!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(passage.title, style: AppTheme.display(size: 24)),
            const SizedBox(height: 12),
            for (final p in passage.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(p, style: AppTheme.body(size: 17, height: 1.7)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final question = _vm.currentQuestion;
        final total = _vm.questions.length;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ContentWidth(
                  maxWidth: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Question ${_vm.questionIndex + 1} of $total',
                            style: AppTheme.body(size: 14, color: AppColors.inkSoft, weight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_vm.canPeekAtStory)
                            TextButton.icon(
                              onPressed: _peekAtStory,
                              icon: const Icon(Icons.menu_book_rounded, size: 20),
                              label: const Text('Look at story'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ChunkyProgressBar(
                        value: (_vm.questionIndex + 1) / total,
                        semanticsLabel: 'Quiz progress',
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 320),
                        transitionBuilder: (child, animation) {
                          final incoming = child.key == ValueKey(question.id);
                          final dx = (incoming == _forward) ? 0.15 : -0.15;
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _QuestionCard(
                          key: ValueKey(question.id),
                          question: question,
                          number: _vm.questionIndex + 1,
                          response: _vm.responseFor(question),
                          controller: question.type == QuestionType.text ? _controllerFor(question) : null,
                          onChanged: _vm.answer,
                          onSubmitted: _vm.isLastQuestion ? (_) => _submit() : (_) => _next(),
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
                    if (!_vm.isFirstQuestion) ...[
                      Expanded(
                        flex: 2,
                        child: ChunkyButton(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          variant: ChunkyVariant.secondary,
                          onPressed: _back,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 3,
                      child: _vm.isLastQuestion
                          ? ChunkyButton(label: 'Submit', icon: Icons.task_alt_rounded, onPressed: _submit)
                          : ChunkyButton(
                              label: _vm.currentAnswered ? 'Next' : 'Skip',
                              icon: Icons.arrow_forward_rounded,
                              variant: _vm.currentAnswered ? ChunkyVariant.primary : ChunkyVariant.soft,
                              onPressed: _next,
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.number,
    required this.response,
    required this.onChanged,
    required this.onSubmitted,
    this.controller,
  });

  final Question question;
  final int number;
  final String response;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                child: Text('$number', style: AppTheme.display(size: 20, color: AppColors.primaryDeep)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  question.skill.label,
                  style: AppTheme.body(size: 13, color: AppColors.inkSoft, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(question.prompt, style: AppTheme.display(size: 22, weight: FontWeight.w600)),
          ),
          const SizedBox(height: 18),
          if (question.type == QuestionType.choice)
            for (final (i, option) in question.options.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  letter: String.fromCharCode(65 + i),
                  label: option,
                  selected: response == option,
                  onTap: () => onChanged(option),
                ),
              )
          else
            TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: AppTheme.body(size: 18),
              decoration: const InputDecoration(
                hintText: 'Type your answer here',
                labelText: 'Your answer',
                alignLabelWithHint: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.letter, required this.label, required this.selected, required this.onTap});

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'Option $letter: $label',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: selected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? AppColors.primary : AppColors.outline, width: selected ? 2.5 : 1.5),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      letter,
                      style: AppTheme.display(size: 18, color: selected ? Colors.white : AppColors.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: AppTheme.body(size: 17, weight: FontWeight.w500))),
                  if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

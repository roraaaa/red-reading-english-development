import 'package:flutter/foundation.dart';

import '../../../../data/repositories/content_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../domain/models/attempt.dart';
import '../../../../domain/models/passage.dart';
import '../../../../domain/models/question.dart';
import '../../../../domain/models/reading_result.dart';
import '../../../../domain/use_cases/answer_grader.dart';
import '../../../../domain/use_cases/reading_evaluator.dart';

enum SessionPhase { reading, quiz, results }

/// Drives one reading session: read the passage, answer the questions, see
/// the results. Assessments are timed; Materials are not.
class ReadingSessionViewModel extends ChangeNotifier {
  ReadingSessionViewModel.assessment({
    required Difficulty difficulty,
    required ContentRepository content,
    required ProgressRepository progress,
    required AnswerGrader grader,
  }) : kind = AttemptKind.assessment,
       _progress = progress,
       _grader = grader,
       _content = content {
    try {
      passage = content.randomAssessment(difficulty, recentIds: progress.recentAssessmentIds);
    } on StateError {
      loadError = 'There are no ${difficulty.label.toLowerCase()} stories yet.';
    }
  }

  ReadingSessionViewModel.material({
    required String passageId,
    required ContentRepository content,
    required ProgressRepository progress,
    required AnswerGrader grader,
  }) : kind = AttemptKind.material,
       _progress = progress,
       _grader = grader,
       _content = content {
    passage = content.material(passageId);
    if (passage == null) loadError = 'That story could not be found.';
  }

  final AttemptKind kind;
  final ContentRepository _content;
  final ProgressRepository _progress;
  final AnswerGrader _grader;

  Passage? passage;
  String? loadError;

  SessionPhase _phase = SessionPhase.reading;
  SessionPhase get phase => _phase;

  bool get isAssessment => kind == AttemptKind.assessment;

  ReadingLevel? get level => passage?.levelId == null ? null : _content.level(passage!.levelId!);

  // ---- Reading ----

  final Stopwatch _stopwatch = Stopwatch();
  int _leftAppCount = 0;

  void startReading() {
    if (isAssessment && !_stopwatch.isRunning && _phase == SessionPhase.reading) {
      _stopwatch.start();
    }
  }

  /// Called when the app goes to the background during a timed reading.
  void onAppHidden() {
    if (isAssessment && _stopwatch.isRunning) _leftAppCount++;
  }

  void finishReading() {
    _stopwatch.stop();
    _phase = SessionPhase.quiz;
    notifyListeners();
  }

  // ---- Quiz ----

  final Map<String, String> _responses = {};
  int _index = 0;

  List<Question> get questions => passage?.questions ?? const [];
  int get questionIndex => _index;
  Question get currentQuestion => questions[_index];
  bool get isFirstQuestion => _index == 0;
  bool get isLastQuestion => _index == questions.length - 1;
  String responseFor(Question q) => _responses[q.id] ?? '';
  bool get currentAnswered => responseFor(currentQuestion).trim().isNotEmpty;
  int get answeredCount => questions.where((q) => responseFor(q).trim().isNotEmpty).length;

  /// Materials let children look back at the story; assessments do not.
  bool get canPeekAtStory => !isAssessment;

  void answer(String response) {
    final wasAnswered = currentAnswered;
    _responses[currentQuestion.id] = response;
    // Typing only needs a rebuild when "answered" flips, to enable buttons.
    if (currentQuestion.type == QuestionType.choice || wasAnswered != currentAnswered) {
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (!isLastQuestion) {
      _index++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (!isFirstQuestion) {
      _index--;
      notifyListeners();
    }
  }

  // ---- Results ----

  ReadingResult? _result;
  ReadingResult? get result => _result;

  bool _isSaving = false;
  bool get isSaving => _isSaving;
  bool _saved = false;
  bool get isSaved => _saved;
  String? _saveError;
  String? get saveError => _saveError;

  Future<void> submit() async {
    final p = passage!;
    final correctById = {
      for (final q in p.questions) q.id: _grader.isCorrect(q, responseFor(q)),
    };
    final correct = correctById.values.where((c) => c).length;
    final total = p.questions.length;

    Duration? readingTime;
    int? wpm;
    ReadingSpeed? speed;
    String? verdict;
    if (isAssessment) {
      readingTime = _stopwatch.elapsed;
      wpm = ReadingEvaluator.wordsPerMinute(p.wordCount, readingTime);
      speed = ReadingEvaluator.speedFor(wpm);
      verdict = ReadingEvaluator.verdict(speed, correct, total);
    }

    _result = ReadingResult(
      kind: kind,
      passage: p,
      responses: {for (final q in p.questions) q.id: responseFor(q).trim()},
      correctById: correctById,
      correct: correct,
      total: total,
      stars: ReadingEvaluator.starsFor(correct, total),
      skillBreakdown: ReadingEvaluator.skillBreakdown(p.questions, correctById),
      skillsToPractice: ReadingEvaluator.skillsToPractice(p.questions, correctById),
      completedAt: DateTime.now(),
      readingTime: readingTime,
      wordsPerMinute: wpm,
      speed: speed,
      verdict: verdict,
      leftAppCount: _leftAppCount,
    );
    _phase = SessionPhase.results;
    notifyListeners();
    await saveResult();
  }

  Future<void> saveResult() async {
    final r = _result;
    if (r == null || _saved || _isSaving) return;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _progress.save(
        Attempt(
          id: '${r.completedAt.millisecondsSinceEpoch}-${r.passage.id}',
          kind: r.kind,
          passageId: r.passage.id,
          passageTitle: r.passage.title,
          levelId: r.passage.levelId,
          difficulty: r.passage.difficulty?.name,
          correct: r.correct,
          total: r.total,
          stars: r.stars,
          readingSeconds: r.readingTime == null ? null : r.readingTime!.inMilliseconds / 1000,
          wordsPerMinute: r.wordsPerMinute,
          leftAppCount: r.leftAppCount,
          completedAt: r.completedAt,
          answers: [
            for (final q in r.passage.questions)
              AnswerRecord(questionId: q.id, response: r.responses[q.id] ?? '', isCorrect: r.correctById[q.id] ?? false),
          ],
        ),
      );
      _saved = true;
    } catch (e) {
      debugPrint('Could not save attempt: $e');
      _saveError = 'Your score could not be saved. Check your connection and try again.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Materials only: read the same story again from the start.
  void retry() {
    _responses.clear();
    _index = 0;
    _result = null;
    _saved = false;
    _saveError = null;
    _phase = SessionPhase.reading;
    notifyListeners();
  }
}

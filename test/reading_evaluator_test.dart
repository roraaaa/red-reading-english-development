import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/models/question.dart';
import 'package:red/domain/models/reading_skill.dart';
import 'package:red/domain/use_cases/reading_evaluator.dart';

Question _q(String id, ReadingSkill skill) =>
    Question(id: id, type: QuestionType.text, prompt: id, skill: skill);

void main() {
  test('stars scale with the share of correct answers', () {
    expect(ReadingEvaluator.starsFor(3, 3), 3);
    expect(ReadingEvaluator.starsFor(2, 3), 2);
    expect(ReadingEvaluator.starsFor(1, 3), 1);
    expect(ReadingEvaluator.starsFor(0, 3), 0);
    expect(ReadingEvaluator.starsFor(4, 5), 2);
    expect(ReadingEvaluator.starsFor(0, 0), 0);
  });

  test('words per minute', () {
    expect(ReadingEvaluator.wordsPerMinute(150, const Duration(minutes: 1)), 150);
    expect(ReadingEvaluator.wordsPerMinute(100, const Duration(seconds: 30)), 200);
    expect(ReadingEvaluator.wordsPerMinute(100, Duration.zero), 0);
  });

  test('speed bands', () {
    expect(ReadingEvaluator.speedFor(60), ReadingSpeed.slow);
    expect(ReadingEvaluator.speedFor(120), ReadingSpeed.steady);
    expect(ReadingEvaluator.speedFor(200), ReadingSpeed.fast);
  });

  test('fast but inaccurate readers are told to slow down', () {
    expect(ReadingEvaluator.verdict(ReadingSpeed.fast, 1, 3), contains('Slow down'));
  });

  test('skills to practice come from wrong answers, without repeats', () {
    final questions = [
      _q('a', ReadingSkill.details),
      _q('b', ReadingSkill.vocabulary),
      _q('c', ReadingSkill.details),
      _q('d', ReadingSkill.inference),
    ];
    final correct = {'a': false, 'b': true, 'c': false, 'd': false};

    expect(
      ReadingEvaluator.skillsToPractice(questions, correct),
      [ReadingSkill.details, ReadingSkill.inference],
    );

    final breakdown = ReadingEvaluator.skillBreakdown(questions, correct);
    final details = breakdown.firstWhere((s) => s.skill == ReadingSkill.details);
    expect((details.correct, details.total), (0, 2));
  });
}

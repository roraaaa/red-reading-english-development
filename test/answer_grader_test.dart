import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/models/question.dart';
import 'package:red/domain/models/reading_skill.dart';
import 'package:red/domain/use_cases/answer_grader.dart';

Question _text(List<List<String>> accepted) => Question(
  id: 'q',
  type: QuestionType.text,
  prompt: 'prompt',
  skill: ReadingSkill.details,
  accepted: accepted,
);

void main() {
  const grader = AnswerGrader();

  group('choice questions', () {
    const question = Question(
      id: 'q',
      type: QuestionType.choice,
      prompt: 'Mars was named after the Roman god of what?',
      skill: ReadingSkill.details,
      options: ['Beauty', 'War', 'The sea'],
      answerIndex: 1,
    );

    test('accepts the correct option', () {
      expect(grader.isCorrect(question, 'War'), isTrue);
    });

    test('rejects other options and blanks', () {
      expect(grader.isCorrect(question, 'Beauty'), isFalse);
      expect(grader.isCorrect(question, ''), isFalse);
    });
  });

  group('typed answers', () {
    final location = _text([
      ['manila'],
      ['philippine'],
    ]);

    test('ignores case and punctuation', () {
      expect(grader.isCorrect(location, 'manila, PHILIPPINES!'), isTrue);
    });

    test('requires every keyword group', () {
      expect(grader.isCorrect(location, 'Manila'), isFalse);
    });

    test('forgives a small typo in a long word', () {
      expect(grader.isCorrect(location, 'Manila Philipines'), isTrue);
    });

    test('does not fuzz short words', () {
      expect(grader.isCorrect(_text([['war']]), 'car'), isFalse);
    });

    test('treats number words and digits the same', () {
      expect(grader.isCorrect(_text([['2']]), 'It has two moons'), isTrue);
      expect(grader.isCorrect(_text([['66 million']]), 'about 66 million years'), isTrue);
    });

    test('treats plurals the same as singular', () {
      expect(grader.isCorrect(_text([['moon']]), 'Moons'), isTrue);
    });

    test('ignores accents', () {
      expect(grader.isCorrect(_text([['josé rizal']]), 'Jose Rizal'), isTrue);
    });

    test('matches multi-word phrases in order', () {
      final q = _text([['red planet']]);
      expect(grader.isCorrect(q, 'the Red Planet'), isTrue);
      expect(grader.isCorrect(q, 'a planet that is red'), isFalse);
    });

    test('rejects blank answers', () {
      expect(grader.isCorrect(location, '   '), isFalse);
    });
  });
}

import '../models/content_snapshot.dart';
import '../models/passage.dart';
import '../models/question.dart';
import 'answer_grader.dart';

/// Checks reading content for mistakes that would break a session or grade
/// a child unfairly. Used by the tests and by `tool/upload_content.dart`
/// before anything is published.
abstract final class ContentValidator {
  /// Returns a list of problems; empty means the content is valid.
  static List<String> validate(ContentSnapshot content, {AnswerGrader grader = const AnswerGrader()}) {
    final problems = <String>[];

    final levelIds = <String>{};
    final levelNumbers = <int>{};
    for (final level in content.levels) {
      if (!levelIds.add(level.id)) problems.add('Level "${level.id}" appears twice.');
      if (!levelNumbers.add(level.number)) problems.add('Level number ${level.number} is used twice.');
    }

    final passageIds = <String>{};
    for (final passage in content.passages) {
      final where = 'Passage "${passage.id}"';
      if (!passageIds.add(passage.id)) problems.add('$where appears twice.');

      final isMaterial = passage.levelId != null;
      final isAssessment = passage.difficulty != null;
      if (isMaterial == isAssessment) {
        problems.add('$where must have exactly one of "level" or "difficulty".');
      }
      if (isMaterial && !levelIds.contains(passage.levelId)) {
        problems.add('$where uses unknown level "${passage.levelId}".');
      }
      if (passage.title.trim().isEmpty) problems.add('$where has no title.');
      if (passage.paragraphs.isEmpty || passage.paragraphs.any((p) => p.trim().isEmpty)) {
        problems.add('$where has missing or empty paragraphs.');
      }
      if (passage.questions.isEmpty) problems.add('$where has no questions.');

      final questionIds = <String>{};
      for (final q in passage.questions) {
        final qWhere = '$where, question "${q.id}"';
        if (!questionIds.add(q.id)) problems.add('$qWhere appears twice.');
        if (q.prompt.trim().isEmpty) problems.add('$qWhere has no prompt.');
        switch (q.type) {
          case QuestionType.choice:
            if (q.options.length < 2) problems.add('$qWhere needs at least 2 options.');
            final answer = q.answerIndex;
            if (answer == null || answer < 0 || answer >= q.options.length) {
              problems.add('$qWhere has an "answer" index outside its options.');
            }
          case QuestionType.text:
            if (q.accepted.isEmpty || q.accepted.any((g) => g.isEmpty)) {
              problems.add('$qWhere needs "accepted" keyword groups, none of them empty.');
            } else if (q.answerText.trim().isEmpty) {
              problems.add('$qWhere needs an "answerText".');
            } else if (!grader.isCorrect(q, q.answerText)) {
              problems.add('$qWhere: its answerText "${q.answerText}" is not accepted by its own keywords.');
            }
        }
      }
    }

    for (final level in content.levels) {
      if (!content.passages.any((p) => p.levelId == level.id)) {
        problems.add('Level "${level.id}" has no stories.');
      }
    }
    for (final difficulty in Difficulty.values) {
      if (!content.passages.any((p) => p.difficulty == difficulty)) {
        problems.add('There are no ${difficulty.name} assessment cards.');
      }
    }
    return problems;
  }
}

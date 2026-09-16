import '../models/content_snapshot.dart';
import '../models/passage.dart';
import '../models/question.dart';
import 'answer_grader.dart';

/// Checks reading content for mistakes that would break a session or grade
/// a reader unfairly. Used by the tests and by `tool/upload_content.dart`
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
    final titles = <String, String>{};
    for (final passage in content.passages) {
      final where = 'Passage "${passage.id}"';
      if (!passageIds.add(passage.id)) problems.add('$where appears twice.');

      final titleKey = AnswerGrader.tokenize(passage.title).join(' ');
      final sameTitle = titles[titleKey];
      if (sameTitle != null) {
        problems.add('$where has the same title as "$sameTitle".');
      } else {
        titles[titleKey] = passage.id;
      }

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

      final image = passage.image;
      if (image != null && !image.startsWith('assets/images/stories/') && !image.startsWith('https://')) {
        problems.add('$where: "image" must be an assets/images/stories/ path or an https:// link.');
      }
      if ((image == null) != (passage.imageCredit == null)) {
        problems.add('$where: "image" and "imageCredit" must be given together, so every photo is credited.');
      }

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

    // Assessment topics are exclusive: a reader should never have practised
    // the exact topic in Materials before being assessed on it.
    final assessments = content.passages.where((p) => p.difficulty != null).toList();
    for (final story in content.passages.where((p) => p.levelId != null)) {
      final storyWords = titleKeywords(story.title);
      for (final card in assessments) {
        final cardWords = titleKeywords(card.title);
        final shared = [
          for (final entry in storyWords.entries)
            if (cardWords.containsKey(entry.key)) entry.value,
        ];
        if (shared.isNotEmpty) {
          problems.add(
            'Story "${story.id}" and assessment card "${card.id}" look like the same topic '
            '(both titles mention: ${shared.join(', ')}). Assessment topics must not appear in Materials.',
          );
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

  /// Words too common in titles to say anything about the topic.
  static const _commonTitleWords = {
    'about', 'amazing', 'every', 'first', 'from', 'give', 'great', 'into',
    'legend', 'life', 'little', 'made', 'make', 'over', 'story', 'that',
    'this', 'under', 'what', 'when', 'where', 'which', 'with', 'world', 'your',
  };

  /// The topic words of a title: words of 4+ letters that are not common
  /// title words. Keys ignore plurals ("honeybees" and "honeybee" match);
  /// values are the words as written, for messages.
  static Map<String, String> titleKeywords(String title) => {
    for (final word in AnswerGrader.normalizedWords(title))
      if (word.length >= 4 && !_commonTitleWords.contains(word)) AnswerGrader.canonical(word): word,
  };
}

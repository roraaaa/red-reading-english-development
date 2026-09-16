import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/models/content_snapshot.dart';
import 'package:red/domain/models/passage.dart';
import 'package:red/domain/models/question.dart';
import 'package:red/domain/models/reading_skill.dart';
import 'package:red/domain/use_cases/answer_grader.dart';
import 'package:red/domain/use_cases/content_validator.dart';

const _question = Question(
  id: 'q1',
  type: QuestionType.choice,
  prompt: 'Pick one',
  skill: ReadingSkill.details,
  options: ['A', 'B'],
  answerIndex: 0,
);

Passage _passage(String id, String title, {String? level, Difficulty? difficulty}) => Passage(
  id: id,
  title: title,
  topic: 'Topic',
  icon: 'book',
  levelId: level,
  difficulty: difficulty,
  paragraphs: const ['Once upon a time.'],
  questions: const [_question],
);

ContentSnapshot _content({required String storyTitle, required String cardTitle}) => ContentSnapshot(
  version: 0,
  levels: const [
    ReadingLevel(id: 'green', number: 1, name: 'Green', colorValue: 0xFF2EAD5F, icon: 'leaf', description: 'Easy'),
  ],
  passages: [
    _passage('story', storyTitle, level: 'green'),
    _passage('card', cardTitle, difficulty: Difficulty.easy),
    _passage('medium', 'Volcanoes of Hawaii', difficulty: Difficulty.medium),
    _passage('hard', 'Deserts at Night', difficulty: Difficulty.hard),
  ],
);

void main() {
  test('different topics pass', () {
    expect(ContentValidator.validate(_content(storyTitle: 'The Red Panda', cardTitle: 'Sea Turtles')), isEmpty);
  });

  test('an assessment topic cannot also be a Materials story', () {
    final problems = ContentValidator.validate(
      _content(storyTitle: 'The Red Planet: Mars', cardTitle: 'Mars and Its Two Moons'),
    );

    expect(problems, hasLength(1));
    expect(problems.single, contains('same topic'));
    expect(problems.single, contains('mars'));
  });

  test('plurals and capital letters still count as the same topic', () {
    final problems = ContentValidator.validate(
      _content(storyTitle: 'Busy Honeybees', cardTitle: 'The HONEYBEE Dance'),
    );

    expect(problems.single, contains('honeybee'));
  });

  test('common title words alone do not count as the same topic', () {
    expect(
      ContentValidator.validate(_content(storyTitle: 'The Amazing Octopus', cardTitle: 'Your Amazing Heart')),
      isEmpty,
    );
  });

  test('two passages cannot share a title', () {
    final problems = ContentValidator.validate(_content(storyTitle: 'Volcanoes of Hawaii', cardTitle: 'Sea Turtles'));

    expect(problems.any((p) => p.contains('same title')), isTrue);
  });

  test('keywords ignore short and common words', () {
    expect(ContentValidator.titleKeywords('Why Your Brain Needs Sleep').keys.toSet(), {'brain', 'need', 'sleep'});
    expect(ContentValidator.titleKeywords('The Red Planet: Mars').keys, contains(AnswerGrader.canonical('mars')));
  });

  test('every picture needs a photo credit and a valid location', () {
    ContentSnapshot withStoryPicture(String? image, ImageCredit? credit) {
      final base = _content(storyTitle: 'The Red Panda', cardTitle: 'Sea Turtles');
      final story = base.passages.first;
      return ContentSnapshot(
        version: 0,
        levels: base.levels,
        passages: [
          Passage(
            id: story.id,
            title: story.title,
            topic: story.topic,
            icon: story.icon,
            levelId: story.levelId,
            paragraphs: story.paragraphs,
            questions: story.questions,
            image: image,
            imageCredit: credit,
          ),
          ...base.passages.skip(1),
        ],
      );
    }

    const credit = ImageCredit(author: 'A. Photographer', license: 'CC0', source: 'https://example.org/photo');

    expect(ContentValidator.validate(withStoryPicture('assets/images/stories/story.jpg', credit)), isEmpty);
    expect(ContentValidator.validate(withStoryPicture('https://example.org/panda.jpg', credit)), isEmpty);
    expect(
      ContentValidator.validate(withStoryPicture('assets/images/stories/story.jpg', null)).single,
      contains('imageCredit'),
    );
    expect(
      ContentValidator.validate(withStoryPicture('C:/Users/me/panda.jpg', credit)).single,
      contains('assets/images/stories/'),
    );
  });
}

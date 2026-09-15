import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/models/content_snapshot.dart';
import 'package:red/domain/models/passage.dart';
import 'package:red/domain/models/question.dart';
import 'package:red/domain/use_cases/answer_grader.dart';

import '../tool/src/firestore_values.dart';

void main() {
  final bundledPassage = {
    'id': 'assess-intramuros',
    'difficulty': 'medium',
    'title': 'Intramuros',
    'topic': 'History',
    'icon': 'church',
    'color': '#E0843D',
    'paragraphs': ['Intramuros is in Manila.'],
    'questions': [
      {
        'id': 'q1',
        'type': 'text',
        'skill': 'details',
        'prompt': 'Where is it?',
        'accepted': [
          ['manila'],
          ['philippine'],
        ],
        'answerText': 'Manila, Philippines',
      },
      {'id': 'q2', 'type': 'choice', 'skill': 'mainIdea', 'prompt': 'Pick one', 'options': ['A', 'B'], 'answer': 1},
    ],
  };

  test('keyword groups are written as maps, because Firestore cannot nest lists', () {
    final passage = Passage.fromJson(bundledPassage, order: 4);
    final json = passage.toJson();

    expect((json['questions'] as List).first['accepted'], [
      {'any': ['manila']},
      {'any': ['philippine']},
    ]);
    expect(json['order'], 4);
    expect(json['color'], '#E0843D');
  });

  test('passages survive a round trip through JSON, in either keyword format', () {
    final original = Passage.fromJson(bundledPassage);
    final copy = Passage.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

    expect(copy.difficulty, Difficulty.medium);
    expect(copy.colorValue, original.colorValue);
    expect(copy.questions.first.accepted, original.questions.first.accepted);
    expect(copy.questions.last.correctAnswerLabel, 'B');
    expect(const AnswerGrader().isCorrect(copy.questions.first, 'manila philippines'), isTrue);
  });

  test('a content snapshot round-trips for the device cache', () {
    const level = ReadingLevel(
      id: 'orange',
      number: 6,
      name: 'Orange',
      colorValue: 0xFFEE7A1E,
      icon: 'fire',
      description: 'Expert stories',
    );
    final snapshot = ContentSnapshot(version: 42, levels: const [level], passages: [Passage.fromJson(bundledPassage)]);
    final copy = ContentSnapshot.fromJson(jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>);

    expect(copy.version, 42);
    expect(copy.levels.single.toJson(), level.toJson());
    expect(copy.passages.single.questions.first.type, QuestionType.text);
  });

  test('uploaded passages encode to Firestore values without nested arrays', () {
    final encoded = FirestoreValues.encodeFields(Passage.fromJson(bundledPassage).toJson());

    void expectNoNestedArrays(Object? node, {bool insideArray = false}) {
      if (node is Map) {
        if (node.containsKey('arrayValue')) {
          expect(insideArray, isFalse, reason: 'array directly inside an array');
          for (final v in (node['arrayValue'] as Map)['values'] as List) {
            expectNoNestedArrays(v, insideArray: true);
          }
          return;
        }
        for (final v in node.values) {
          expectNoNestedArrays(v);
        }
      }
    }

    expectNoNestedArrays(encoded);
    expect(encoded['order'], {'integerValue': '0'});
    expect(() => FirestoreValues.encode([['a']]), throwsArgumentError);
  });
}

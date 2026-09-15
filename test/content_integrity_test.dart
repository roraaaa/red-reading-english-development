import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/services/content_files.dart';
import 'package:red/domain/models/content_snapshot.dart';
import 'package:red/domain/models/passage.dart';
import 'package:red/domain/use_cases/content_validator.dart';

/// Guards the hand-written content in assets/content. The upload tool runs
/// the same validator before publishing to Firestore.
void main() {
  late ContentSnapshot content;

  setUpAll(() async {
    content = await ContentFiles.load((path) => File(path).readAsString());
  });

  test('all content passes validation', () {
    expect(ContentValidator.validate(content), isEmpty);
  });

  test('six colour levels in order, three stories each', () {
    expect(content.levels.map((l) => l.id), ['green', 'aqua', 'blue', 'violet', 'pink', 'orange']);
    expect(content.levels.map((l) => l.number), [1, 2, 3, 4, 5, 6]);
    for (final level in content.levels) {
      expect(content.passages.where((p) => p.levelId == level.id), hasLength(3), reason: level.id);
    }
  });

  test('eight assessment cards per difficulty', () {
    for (final difficulty in Difficulty.values) {
      expect(content.passages.where((p) => p.difficulty == difficulty), hasLength(8), reason: difficulty.name);
    }
  });

  test('no topic is used twice', () {
    final titles = content.passages.map((p) => p.title.toLowerCase()).toList();
    expect(titles.toSet(), hasLength(titles.length));
  });

  test('bundled files keep their order', () {
    final green = content.passages.where((p) => p.levelId == 'green').toList();
    expect(green.map((p) => p.order), [0, 1, 2]);
    expect(green.first.id, 'red-panda');
  });
}

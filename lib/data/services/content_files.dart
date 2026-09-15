import 'dart:convert';

import '../../domain/models/content_snapshot.dart';
import '../../domain/models/passage.dart';

/// Reads the content JSON files (levels, one file per level, one file per
/// assessment difficulty) into a [ContentSnapshot].
///
/// Pure Dart so the app (asset bundle), the tests and the upload tool
/// (files on disk) all read the files the same way.
abstract final class ContentFiles {
  static const root = 'assets/content';
  static const levelsPath = '$root/levels.json';
  static String materialsPath(String levelId) => '$root/materials/$levelId.json';
  static String assessmentsPath(Difficulty difficulty) => '$root/assessments/${difficulty.name}.json';

  static Future<ContentSnapshot> load(Future<String> Function(String path) readText, {int version = 0}) async {
    Future<Map<String, dynamic>> readJson(String path) async =>
        jsonDecode(await readText(path)) as Map<String, dynamic>;

    final levels = [
      for (final l in (await readJson(levelsPath))['levels'] as List)
        ReadingLevel.fromJson(l as Map<String, dynamic>),
    ]..sort((a, b) => a.number.compareTo(b.number));

    final passages = <Passage>[
      for (final level in levels) ..._passages(await readJson(materialsPath(level.id))),
      for (final d in Difficulty.values) ..._passages(await readJson(assessmentsPath(d))),
    ];
    return ContentSnapshot(version: version, levels: levels, passages: passages);
  }

  static List<Passage> _passages(Map<String, dynamic> json) => [
    for (final (i, p) in (json['passages'] as List).indexed)
      Passage.fromJson(p as Map<String, dynamic>, order: i),
  ];
}

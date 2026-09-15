// Publishes the reading content in assets/content to Firestore.
//
// Check the content only (no upload, no key needed):
//   dart run tool/upload_content.dart --dry-run
//
// Publish:
//   dart run tool/upload_content.dart --key path\to\service-account.json
//
// The key comes from Firebase Console > Project settings > Service accounts >
// Generate new private key. Keep it private and out of git.
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:red/data/services/content_files.dart';
import 'package:red/data/services/firestore_content_paths.dart';
import 'package:red/domain/use_cases/content_validator.dart';

import 'src/firestore_rest.dart';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final keyPath = _option(args, '--key') ?? Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];

  final version = DateTime.now().millisecondsSinceEpoch;
  final content = await ContentFiles.load((path) => File(path).readAsString(), version: version);

  final problems = ContentValidator.validate(content);
  if (problems.isNotEmpty) {
    stderr.writeln('Nothing was published. Fix these ${problems.length} problem(s) first:');
    for (final problem in problems) {
      stderr.writeln('  - $problem');
    }
    exitCode = 1;
    return;
  }

  final materials = content.passages.where((p) => p.levelId != null).length;
  final cards = content.passages.length - materials;
  stdout.writeln('Content OK: ${content.levels.length} levels, $materials stories, $cards assessment cards.');
  if (dryRun) return;

  if (keyPath == null) {
    stderr.writeln('Pass --key path\\to\\service-account.json to publish (or use --dry-run to only check).');
    exitCode = 64;
    return;
  }

  final key = jsonDecode(await File(keyPath).readAsString()) as Map<String, dynamic>;
  final projectId = key['project_id'] as String;
  final client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(key),
    ['https://www.googleapis.com/auth/datastore'],
  );

  try {
    final firestore = FirestoreRest(client, projectId);
    const levelsPath = FirestoreContentPaths.levelsCollection;
    const passagesPath = FirestoreContentPaths.passagesCollection;
    final levelIds = {for (final l in content.levels) l.id};
    final passageIds = {for (final p in content.passages) p.id};
    final staleLevels = (await firestore.listDocumentIds(levelsPath)).difference(levelIds);
    final stalePassages = (await firestore.listDocumentIds(passagesPath)).difference(passageIds);

    final writes = [
      for (final l in content.levels) firestore.setWrite('$levelsPath/${l.id}', l.toJson()),
      for (final p in content.passages) firestore.setWrite('$passagesPath/${p.id}', p.toJson()),
      for (final id in staleLevels) firestore.deleteWrite('$levelsPath/$id'),
      for (final id in stalePassages) firestore.deleteWrite('$passagesPath/$id'),
    ];

    // Content goes up first; the version is bumped last, so apps only start
    // downloading once everything is in place.
    const batchSize = FirestoreRest.maxWritesPerCommit;
    for (var start = 0; start < writes.length; start += batchSize) {
      final end = start + batchSize < writes.length ? start + batchSize : writes.length;
      await firestore.commit(writes.sublist(start, end));
    }
    await firestore.commit([
      firestore.setWrite(FirestoreContentPaths.metaDocument, {
        'version': version,
        'publishedAt': DateTime.now().toUtc().toIso8601String(),
        'levels': content.levels.length,
        'passages': content.passages.length,
      }),
    ]);

    stdout.writeln('Published version $version to "$projectId".');
    if (staleLevels.isNotEmpty || stalePassages.isNotEmpty) {
      stdout.writeln('Removed: ${[...staleLevels, ...stalePassages].join(', ')}');
    }
  } finally {
    client.close();
  }
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

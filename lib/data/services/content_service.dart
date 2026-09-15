import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../domain/models/content_snapshot.dart';
import '../../domain/models/passage.dart';
import 'content_files.dart';
import 'firestore_content_paths.dart';

/// The reading content bundled inside the app (assets/content). Always
/// available, including offline and in demo mode.
abstract interface class ContentSource {
  Future<ContentSnapshot> load();
}

class BundledContentSource implements ContentSource {
  const BundledContentSource({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  @override
  Future<ContentSnapshot> load() => ContentFiles.load((path) => (_bundle ?? rootBundle).loadString(path));
}

/// Reading content published online.
abstract interface class CloudContentSource {
  /// The version of the published content, or null if nothing is published.
  Future<int?> fetchVersion();

  Future<ContentSnapshot> fetchSnapshot();
}

/// Content published to Firestore by `tool/upload_content.dart`.
class FirestoreContentSource implements CloudContentSource {
  FirestoreContentSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<int?> fetchVersion() async {
    final meta = await _firestore.doc(FirestoreContentPaths.metaDocument).get();
    return (meta.data()?['version'] as num?)?.toInt();
  }

  @override
  Future<ContentSnapshot> fetchSnapshot() async {
    final version = await fetchVersion() ?? 0;
    final levels = await _firestore.collection(FirestoreContentPaths.levelsCollection).get();
    final passages = await _firestore.collection(FirestoreContentPaths.passagesCollection).get();
    return ContentSnapshot(
      version: version,
      levels: [for (final doc in levels.docs) ReadingLevel.fromJson(doc.data())],
      passages: [for (final doc in passages.docs) Passage.fromJson(doc.data())],
    );
  }
}

/// Where published reading content lives in Firestore.
///
/// Plain Dart (no Flutter imports) so `tool/upload_content.dart` can share it.
abstract final class FirestoreContentPaths {
  /// Holds `version`: the upload time in milliseconds since epoch.
  static const metaDocument = 'content/meta';

  /// `levels/{levelId}`
  static const levelsCollection = 'levels';

  /// `passages/{passageId}`; materials have `level`, cards have `difficulty`.
  static const passagesCollection = 'passages';
}

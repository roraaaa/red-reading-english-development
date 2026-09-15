import 'passage.dart';

/// All reading content at one moment: the Materials levels plus every
/// passage (materials and assessment cards).
class ContentSnapshot {
  const ContentSnapshot({
    required this.version,
    required this.levels,
    required this.passages,
  });

  /// 0 for the copy bundled with the app; the upload time (milliseconds
  /// since epoch) for content published to Firestore.
  final int version;
  final List<ReadingLevel> levels;
  final List<Passage> passages;

  Map<String, dynamic> toJson() => {
    'version': version,
    'levels': [for (final l in levels) l.toJson()],
    'passages': [for (final p in passages) p.toJson()],
  };

  factory ContentSnapshot.fromJson(Map<String, dynamic> json) => ContentSnapshot(
    version: json['version'] as int? ?? 0,
    levels: [
      for (final l in json['levels'] as List) ReadingLevel.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
    passages: [
      for (final p in json['passages'] as List) Passage.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
  );
}

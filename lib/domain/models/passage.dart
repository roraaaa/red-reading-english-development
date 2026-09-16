import 'question.dart';

enum Difficulty {
  easy('Easy', 'Short stories with simple words'),
  medium('Medium', 'Longer stories with some new words'),
  hard('Hard', 'Challenging stories and tricky questions');

  const Difficulty(this.label, this.description);

  final String label;
  final String description;

  static Difficulty? fromName(String? name) {
    for (final d in Difficulty.values) {
      if (d.name == name) return d;
    }
    return null;
  }
}

int _parseColor(String hex) => int.parse(hex.replaceFirst('#', 'FF'), radix: 16);

String _formatColor(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A colour level for Materials, like the colour bands on library reading
/// cards. Higher numbers are harder.
class ReadingLevel {
  const ReadingLevel({
    required this.id,
    required this.number,
    required this.name,
    required this.colorValue,
    required this.icon,
    required this.description,
  });

  final String id;
  final int number;
  final String name;
  final int colorValue;
  final String icon;
  final String description;

  factory ReadingLevel.fromJson(Map<String, dynamic> json) => ReadingLevel(
    id: json['id'] as String,
    number: json['number'] as int,
    name: json['name'] as String,
    colorValue: _parseColor(json['color'] as String),
    icon: json['icon'] as String,
    description: json['description'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'name': name,
    'color': _formatColor(colorValue),
    'icon': icon,
    'description': description,
  };
}

/// Who made a story's picture and under which licence, so it can be
/// credited in the app.
class ImageCredit {
  const ImageCredit({
    required this.author,
    required this.license,
    required this.source,
    this.licenseUrl,
  });

  final String author;

  /// Short licence name, e.g. "CC BY-SA 4.0" or "Public domain".
  final String license;

  /// Web page where the original picture was found.
  final String source;
  final String? licenseUrl;

  String get label => 'Photo: $author ($license)';

  factory ImageCredit.fromJson(Map<String, dynamic> json) => ImageCredit(
    author: json['author'] as String,
    license: json['license'] as String,
    source: json['source'] as String,
    licenseUrl: json['licenseUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'author': author,
    'license': license,
    'source': source,
    'licenseUrl': ?licenseUrl,
  };
}

/// One topic card: a short text about a single subject plus its questions.
/// Materials have a [levelId]; assessment cards have a [difficulty].
class Passage {
  const Passage({
    required this.id,
    required this.title,
    required this.topic,
    required this.icon,
    required this.paragraphs,
    required this.questions,
    this.colorValue,
    this.levelId,
    this.difficulty,
    this.order = 0,
    this.image,
    this.imageCredit,
  });

  final String id;
  final String title;
  final String topic;
  final String icon;
  final int? colorValue;
  final String? levelId;
  final Difficulty? difficulty;

  /// Position within its level or difficulty (Firestore does not keep the
  /// order of the JSON files, so it is stored explicitly).
  final int order;
  final List<String> paragraphs;
  final List<Question> questions;

  /// A picture for the card: an app asset path (`assets/images/stories/...`)
  /// or an `https://` link. Without one, the card shows [icon].
  final String? image;
  final ImageCredit? imageCredit;

  int get wordCount => paragraphs
      .expand((p) => p.split(RegExp(r'\s+')))
      .where((w) => w.isNotEmpty)
      .length;

  /// [order] is used when the JSON has no `order` field (the bundled files
  /// use their position in the file instead).
  factory Passage.fromJson(Map<String, dynamic> json, {int order = 0}) => Passage(
    id: json['id'] as String,
    title: json['title'] as String,
    topic: json['topic'] as String,
    icon: json['icon'] as String,
    colorValue: json['color'] == null ? null : _parseColor(json['color'] as String),
    levelId: json['level'] as String?,
    difficulty: Difficulty.fromName(json['difficulty'] as String?),
    order: json['order'] as int? ?? order,
    image: json['image'] as String?,
    imageCredit: json['imageCredit'] == null
        ? null
        : ImageCredit.fromJson(Map<String, dynamic>.from(json['imageCredit'] as Map)),
    paragraphs: (json['paragraphs'] as List).cast<String>(),
    questions: (json['questions'] as List)
        .map((q) => Question.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'topic': topic,
    'icon': icon,
    if (colorValue != null) 'color': _formatColor(colorValue!),
    if (levelId != null) 'level': levelId,
    if (difficulty != null) 'difficulty': difficulty!.name,
    'order': order,
    'image': ?image,
    if (imageCredit != null) 'imageCredit': imageCredit!.toJson(),
    'paragraphs': paragraphs,
    'questions': [for (final q in questions) q.toJson()],
  };
}

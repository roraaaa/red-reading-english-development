enum AttemptKind { assessment, material }

class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.response,
    required this.isCorrect,
  });

  final String questionId;
  final String response;
  final bool isCorrect;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'response': response,
    'isCorrect': isCorrect,
  };

  factory AnswerRecord.fromJson(Map<String, dynamic> json) => AnswerRecord(
    questionId: json['questionId'] as String,
    response: json['response'] as String? ?? '',
    isCorrect: json['isCorrect'] as bool? ?? false,
  );
}

/// A finished Assess or Materials session, saved to the user's account.
class Attempt {
  const Attempt({
    required this.id,
    required this.kind,
    required this.passageId,
    required this.passageTitle,
    required this.correct,
    required this.total,
    required this.stars,
    required this.completedAt,
    required this.answers,
    this.levelId,
    this.difficulty,
    this.readingSeconds,
    this.wordsPerMinute,
    this.leftAppCount = 0,
  });

  final String id;
  final AttemptKind kind;
  final String passageId;
  final String passageTitle;
  final String? levelId;
  final String? difficulty;
  final int correct;
  final int total;
  final int stars;
  final double? readingSeconds;
  final int? wordsPerMinute;
  final int leftAppCount;
  final DateTime completedAt;
  final List<AnswerRecord> answers;

  double get ratio => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'passageId': passageId,
    'passageTitle': passageTitle,
    'levelId': levelId,
    'difficulty': difficulty,
    'correct': correct,
    'total': total,
    'stars': stars,
    'readingSeconds': readingSeconds,
    'wordsPerMinute': wordsPerMinute,
    'leftAppCount': leftAppCount,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'answers': answers.map((a) => a.toJson()).toList(),
  };

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
    id: json['id'] as String,
    kind: json['kind'] == 'assessment' ? AttemptKind.assessment : AttemptKind.material,
    passageId: json['passageId'] as String,
    passageTitle: json['passageTitle'] as String? ?? '',
    levelId: json['levelId'] as String?,
    difficulty: json['difficulty'] as String?,
    correct: json['correct'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    stars: json['stars'] as int? ?? 0,
    readingSeconds: (json['readingSeconds'] as num?)?.toDouble(),
    wordsPerMinute: json['wordsPerMinute'] as int?,
    leftAppCount: json['leftAppCount'] as int? ?? 0,
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    answers: ((json['answers'] as List?) ?? const [])
        .map((a) => AnswerRecord.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
  );
}

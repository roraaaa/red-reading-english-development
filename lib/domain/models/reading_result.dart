import '../use_cases/reading_evaluator.dart';
import 'attempt.dart';
import 'passage.dart';
import 'reading_skill.dart';

/// Everything the results screen and the PDF report need about a session.
class ReadingResult {
  const ReadingResult({
    required this.kind,
    required this.passage,
    required this.responses,
    required this.correctById,
    required this.correct,
    required this.total,
    required this.stars,
    required this.skillBreakdown,
    required this.skillsToPractice,
    required this.completedAt,
    this.readingTime,
    this.wordsPerMinute,
    this.speed,
    this.verdict,
    this.leftAppCount = 0,
  });

  final AttemptKind kind;
  final Passage passage;

  /// Question id -> what the child answered (option text or typed text).
  final Map<String, String> responses;
  final Map<String, bool> correctById;
  final int correct;
  final int total;
  final int stars;
  final List<SkillScore> skillBreakdown;
  final List<ReadingSkill> skillsToPractice;
  final DateTime completedAt;

  /// Assess only.
  final Duration? readingTime;
  final int? wordsPerMinute;
  final ReadingSpeed? speed;
  final String? verdict;
  final int leftAppCount;

  bool get isAssessment => kind == AttemptKind.assessment;
  bool get isPerfect => total > 0 && correct == total;
}

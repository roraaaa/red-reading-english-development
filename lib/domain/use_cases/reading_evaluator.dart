import '../models/question.dart';
import '../models/reading_skill.dart';

enum ReadingSpeed {
  slow('Careful pace'),
  steady('Steady pace'),
  fast('Speedy pace');

  const ReadingSpeed(this.label);
  final String label;
}

class SkillScore {
  const SkillScore(this.skill, this.correct, this.total);

  final ReadingSkill skill;
  final int correct;
  final int total;
}

/// Scoring rules shared by Assess and Materials.
abstract final class ReadingEvaluator {
  static int starsFor(int correct, int total) {
    if (total == 0) return 0;
    final ratio = correct / total;
    if (ratio >= 0.85) return 3;
    if (ratio >= 0.6) return 2;
    if (ratio >= 0.3) return 1;
    return 0;
  }

  static int wordsPerMinute(int words, Duration readingTime) {
    final minutes = readingTime.inMilliseconds / 60000;
    if (minutes <= 0) return 0;
    return (words / minutes).round();
  }

  /// Rough silent-reading bands for readers aged about 7 to 12.
  static ReadingSpeed speedFor(int wordsPerMinute) {
    if (wordsPerMinute < 80) return ReadingSpeed.slow;
    if (wordsPerMinute < 150) return ReadingSpeed.steady;
    return ReadingSpeed.fast;
  }

  /// A one-line, encouraging summary that combines speed and accuracy.
  static String verdict(ReadingSpeed speed, int correct, int total) {
    final ratio = total == 0 ? 0 : correct / total;
    final accurate = ratio >= 0.8;
    final okay = ratio >= 0.5;
    return switch (speed) {
      ReadingSpeed.fast when accurate =>
        'Speedy and sharp! You read quickly and understood it well.',
      ReadingSpeed.fast =>
        'You are a fast reader! Slow down a little to catch more details.',
      ReadingSpeed.steady when accurate =>
        'Great balance! Steady reading and strong understanding.',
      ReadingSpeed.steady when okay =>
        'Good job! A little more focus will boost your score.',
      ReadingSpeed.steady =>
        'Nice try! Re-read tricky sentences as you go.',
      ReadingSpeed.slow when okay =>
        'Careful reader! You understood a lot. Speed comes with practice.',
      ReadingSpeed.slow =>
        'Keep going! Reading a little every day makes it easier and faster.',
    };
  }

  static List<SkillScore> skillBreakdown(
    List<Question> questions,
    Map<String, bool> correctById,
  ) {
    final totals = <ReadingSkill, List<int>>{};
    for (final q in questions) {
      final entry = totals.putIfAbsent(q.skill, () => [0, 0]);
      entry[1]++;
      if (correctById[q.id] ?? false) entry[0]++;
    }
    return [
      for (final e in totals.entries) SkillScore(e.key, e.value[0], e.value[1]),
    ];
  }

  /// Skills of the questions answered wrongly, in question order, no repeats.
  static List<ReadingSkill> skillsToPractice(
    List<Question> questions,
    Map<String, bool> correctById,
  ) {
    final skills = <ReadingSkill>[];
    for (final q in questions) {
      if (!(correctById[q.id] ?? false) && !skills.contains(q.skill)) {
        skills.add(q.skill);
      }
    }
    return skills;
  }
}

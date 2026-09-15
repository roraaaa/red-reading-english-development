import 'reading_skill.dart';

enum QuestionType { choice, text }

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.skill,
    this.options = const [],
    this.answerIndex,
    this.accepted = const [],
    this.answerText = '',
  });

  final String id;
  final QuestionType type;
  final String prompt;
  final ReadingSkill skill;

  /// Choice questions only.
  final List<String> options;
  final int? answerIndex;

  /// Text questions only. Every inner list is a group of alternative
  /// phrases; an answer is correct when it matches one phrase from EACH group.
  /// e.g. `[["manila"], ["philippines"]]`.
  final List<List<String>> accepted;

  /// Model answer shown to the child after grading (text questions).
  final String answerText;

  String get correctAnswerLabel =>
      type == QuestionType.choice ? options[answerIndex!] : answerText;

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'text' ? QuestionType.text : QuestionType.choice;
    return Question(
      id: json['id'] as String,
      type: type,
      prompt: json['prompt'] as String,
      skill: ReadingSkill.fromName(json['skill'] as String?),
      options: (json['options'] as List?)?.cast<String>() ?? const [],
      answerIndex: json['answer'] as int?,
      accepted: [
        for (final group in (json['accepted'] as List?) ?? const [])
          // The bundled JSON writes groups as lists. Firestore cannot store a
          // list inside a list, so uploaded content uses {"any": [...]} maps.
          (group is Map ? group['any'] as List : group as List).cast<String>(),
      ],
      answerText: json['answerText'] as String? ?? '',
    );
  }

  /// Firestore-safe JSON (keyword groups are written as `{"any": [...]}`).
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'prompt': prompt,
    'skill': skill.name,
    if (type == QuestionType.choice) ...{
      'options': options,
      'answer': answerIndex,
    },
    if (type == QuestionType.text) ...{
      'accepted': [
        for (final group in accepted) {'any': group},
      ],
      'answerText': answerText,
    },
  };
}

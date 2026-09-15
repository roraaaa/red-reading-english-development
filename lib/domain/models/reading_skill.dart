/// The comprehension skill a question checks. Wrong answers are grouped by
/// skill so the results screen can give targeted advice.
enum ReadingSkill {
  details(
    label: 'Finding details',
    adviceTitle: 'Skim and scan for details',
    advice:
        'When a question asks who, what, where or when, look back for key '
        'words from the question. Names, places and numbers are usually '
        'written exactly in the story.',
  ),
  vocabulary(
    label: 'Word meaning',
    adviceTitle: 'Get to know new words',
    advice:
        'If you meet a word you do not know, read the sentences around it. '
        'They often give clues about what the word means. Keep a list of new '
        'words and try using them when you talk.',
  ),
  mainIdea(
    label: 'Main idea',
    adviceTitle: 'Find the big idea',
    advice:
        'After each paragraph, stop and ask yourself: "What was this mostly '
        'about?" The title and the first sentence are great hints.',
  ),
  sequence(
    label: 'Order of events',
    adviceTitle: 'Follow what happens first, next and last',
    advice:
        'Watch for time words like first, then, after, later and finally. '
        'Picture each event like a scene in a movie.',
  ),
  inference(
    label: 'Reading between the lines',
    adviceTitle: 'Think like a detective',
    advice:
        'Some answers are not written word for word. Use the clues in the '
        'story and what you already know to figure out why something happened '
        'or how a character feels.',
  );

  const ReadingSkill({
    required this.label,
    required this.adviceTitle,
    required this.advice,
  });

  final String label;
  final String adviceTitle;
  final String advice;

  static ReadingSkill fromName(String? name) => ReadingSkill.values.firstWhere(
    (s) => s.name == name,
    orElse: () => ReadingSkill.details,
  );
}

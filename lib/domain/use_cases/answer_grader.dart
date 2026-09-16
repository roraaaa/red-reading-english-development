import '../models/question.dart';

/// Grades answers without a network call.
///
/// Typed answers are forgiving on purpose, because readers misspell words:
/// case, punctuation, accents, plurals ("moons" = "moon"), number words
/// ("two" = "2") and one-letter typos in longer words are all accepted.
class AnswerGrader {
  const AnswerGrader();

  bool isCorrect(Question question, String response) {
    if (response.trim().isEmpty) return false;
    if (question.type == QuestionType.choice) {
      return response == question.correctAnswerLabel;
    }
    final answerTokens = tokenize(response);
    return question.accepted.every(
      (group) => group.any((phrase) => _containsPhrase(answerTokens, tokenize(phrase))),
    );
  }

  static const _numberWords = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
    'fourteen': '14', 'fifteen': '15', 'sixteen': '16', 'seventeen': '17',
    'eighteen': '18', 'nineteen': '19', 'twenty': '20',
  };

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e',
    'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o',
    'ô': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ñ': 'n',
  };

  static List<String> tokenize(String text) => normalizedWords(text).map(canonical).toList();

  /// Lower-case words with accents and punctuation removed,
  /// e.g. "José's Moons!" -> [jose, s, moons].
  static List<String> normalizedWords(String text) {
    var lower = text.toLowerCase();
    _accents.forEach((from, to) => lower = lower.replaceAll(from, to));
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Number words become digits and plurals become singular
  /// ("two" -> "2", "moons" -> "moon").
  static String canonical(String token) {
    final number = _numberWords[token];
    if (number != null) return number;
    if (token.length > 3 && token.endsWith('s') && !token.endsWith('ss')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  static bool _containsPhrase(List<String> haystack, List<String> phrase) {
    if (phrase.isEmpty || phrase.length > haystack.length) return false;
    for (var start = 0; start <= haystack.length - phrase.length; start++) {
      var matched = true;
      for (var i = 0; i < phrase.length; i++) {
        if (!_similar(haystack[start + i], phrase[i])) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  static bool _similar(String a, String b) {
    if (a == b) return true;
    final isNumber = RegExp(r'^\d+$');
    if (isNumber.hasMatch(a) || isNumber.hasMatch(b)) return false;
    final shortest = a.length < b.length ? a.length : b.length;
    if (shortest < 5) return false;
    final allowed = shortest >= 9 ? 2 : 1;
    return _levenshtein(a, b, allowed) <= allowed;
  }

  /// Edit distance, stopping early once it exceeds [limit].
  static int _levenshtein(String a, String b, int limit) {
    if ((a.length - b.length).abs() > limit) return limit + 1;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = current[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = [
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
        if (current[j] < rowMin) rowMin = current[j];
      }
      if (rowMin > limit) return limit + 1;
      previous = current;
    }
    return previous[b.length];
  }
}

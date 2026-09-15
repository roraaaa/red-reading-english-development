/// A word in a paragraph, with its character range, so the word being read
/// aloud can be highlighted and a tapped word can be spoken.
class WordToken {
  const WordToken(this.start, this.end, this.text);

  final int start;
  final int end;

  /// The word as written, including punctuation touching it, e.g. `race!"`.
  final String text;

  static final _edgePunctuation = RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true);

  /// The word without surrounding punctuation, e.g. `race`.
  String get spoken => text.replaceAll(_edgePunctuation, '');
}

abstract final class WordSplitter {
  static final _word = RegExp(r'\S+');

  static List<WordToken> split(String text) => [
    for (final m in _word.allMatches(text)) WordToken(m.start, m.end, m.group(0)!),
  ];

  /// Index of the word at (or just after) character [offset].
  static int? indexAt(List<WordToken> words, int offset) {
    if (words.isEmpty) return null;
    for (var i = 0; i < words.length; i++) {
      if (words[i].end > offset) return i;
    }
    return words.length - 1;
  }
}

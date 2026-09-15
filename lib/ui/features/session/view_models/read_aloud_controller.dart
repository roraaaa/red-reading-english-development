import 'package:flutter/foundation.dart';

import '../../../../data/services/speech_service.dart';
import '../../../../domain/use_cases/word_splitter.dart';

/// Reads a passage aloud paragraph by paragraph, tracking the word being
/// spoken, and speaks single words when they are tapped.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController({required SpeechService speech, required List<String> paragraphs})
    : _speech = speech,
      paragraphs = List.unmodifiable(paragraphs),
      words = List.unmodifiable([for (final p in paragraphs) WordSplitter.split(p)]);

  final SpeechService _speech;
  final List<String> paragraphs;
  final List<List<WordToken>> words;

  bool _isPlaying = false;
  int? _activeParagraph;
  int? _activeWord;
  (int, int)? _tappedWord;
  bool _isUnavailable = false;

  /// Once the voice has worked, a later hiccup is not treated as "this
  /// device can't read aloud".
  bool _hasSpoken = false;

  int _resumeParagraph = 0;
  int _resumeWord = 0;

  /// Bumped whenever playback is interrupted, so stale loops and callbacks
  /// stop touching state.
  int _run = 0;
  bool _disposed = false;

  bool get isPlaying => _isPlaying;
  int? get activeParagraph => _activeParagraph;
  int? get activeWord => _activeWord;
  bool get isUnavailable => _isUnavailable;
  bool get canResume => _resumeParagraph > 0 || _resumeWord > 0;

  bool isTapped(int paragraph, int word) => _tappedWord == (paragraph, word);

  /// Word to highlight in [paragraph]: a tapped word, or the word being read.
  int? highlightedWordIn(int paragraph) {
    final tapped = _tappedWord;
    if (tapped != null) return tapped.$1 == paragraph ? tapped.$2 : null;
    return _activeParagraph == paragraph ? _activeWord : null;
  }

  /// Starts reading, or continues from where it was paused.
  Future<void> play() async {
    if (_isPlaying || paragraphs.isEmpty) return;
    final run = ++_run;
    final wordStillSpeaking = _tappedWord != null;
    _isPlaying = true;
    _isUnavailable = false;
    _tappedWord = null;
    _notify();
    if (wordStillSpeaking) await _speech.stop();
    if (run != _run) return;

    for (var p = _resumeParagraph; p < paragraphs.length; p++) {
      final tokens = words[p];
      if (tokens.isEmpty) continue;
      final firstWord = p == _resumeParagraph ? _resumeWord.clamp(0, tokens.length - 1) : 0;
      final base = tokens[firstWord].start;

      _resumeParagraph = p;
      _resumeWord = firstWord;
      _activeParagraph = p;
      _activeWord = firstWord;
      _notify();

      final outcome = await _speech.speak(
        paragraphs[p].substring(base),
        onProgress: (start, end) {
          if (run != _run) return;
          _hasSpoken = true;
          final index = WordSplitter.indexAt(tokens, base + start);
          if (index != null && index != _activeWord) {
            _activeWord = index;
            _resumeWord = index;
            _notify();
          }
        },
      );

      if (run != _run) return; // Paused, stopped or a word was tapped.
      switch (outcome) {
        case SpeechOutcome.failed:
          _isUnavailable = !_hasSpoken;
          _isPlaying = false;
          if (_isUnavailable) _resetPosition();
          _notify();
          return;
        case SpeechOutcome.stopped:
          _isPlaying = false;
          _notify();
          return;
        case SpeechOutcome.completed:
          _hasSpoken = true;
          _resumeWord = 0;
      }
    }

    _resetPosition();
    _isPlaying = false;
    _notify();
  }

  /// Stops reading but remembers the position.
  Future<void> pause() async {
    if (!_isPlaying) return;
    _run++;
    _isPlaying = false;
    _notify();
    await _speech.stop();
  }

  /// Stops reading and goes back to the beginning.
  Future<void> stop() async {
    final wasSpeaking = _isPlaying || _tappedWord != null;
    _run++;
    _isPlaying = false;
    _tappedWord = null;
    _resetPosition();
    _notify();
    if (wasSpeaking) await _speech.stop();
  }

  /// Speaks one tapped word. Pauses reading if it was playing, and cuts off
  /// a previously tapped word so quick taps each get heard.
  Future<void> speakWord(int paragraph, int word) async {
    final spoken = words[paragraph][word].spoken;
    if (spoken.isEmpty) return;

    final run = ++_run;
    final wasSpeaking = _isPlaying || _tappedWord != null;
    _isPlaying = false;
    _isUnavailable = false;
    _tappedWord = (paragraph, word);
    _notify();
    if (wasSpeaking) await _speech.stop();
    if (run != _run) return;

    final outcome = await _speech.speak(spoken);
    if (run != _run) return;
    _tappedWord = null;
    if (outcome == SpeechOutcome.completed) _hasSpoken = true;
    if (outcome == SpeechOutcome.failed) _isUnavailable = !_hasSpoken;
    _notify();
  }

  void _resetPosition() {
    _resumeParagraph = 0;
    _resumeWord = 0;
    _activeParagraph = null;
    _activeWord = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_isPlaying || _tappedWord != null) _speech.stop();
    _run++;
    super.dispose();
  }
}

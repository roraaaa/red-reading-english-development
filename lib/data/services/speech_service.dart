import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SpeechOutcome { completed, stopped, failed }

/// Called while speaking with the character range of the word being spoken,
/// relative to the text passed to [SpeechService.speak].
typedef SpeechProgressCallback = void Function(int start, int end);

abstract interface class SpeechService {
  /// Speaks [text] and completes when it finishes, is stopped or fails.
  Future<SpeechOutcome> speak(String text, {SpeechProgressCallback? onProgress});

  Future<void> stop();

  void dispose();
}

/// Reads text aloud with the phone's (or browser's) built-in voice.
class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<bool>? _ready;
  Completer<SpeechOutcome>? _current;
  SpeechProgressCallback? _onProgress;
  bool _started = false;

  Future<bool> _init() async {
    try {
      _tts.setStartHandler(() => _started = true);
      _tts.setCompletionHandler(() => _finish(SpeechOutcome.completed));
      // A cancel event from an utterance we already replaced must not end
      // the new one, so only honour cancels after the new one has started.
      _tts.setCancelHandler(() {
        if (_started) _finish(SpeechOutcome.stopped);
      });
      _tts.setErrorHandler((message) {
        // Browsers report a cancelled utterance as an "interrupted" or
        // "canceled" error; that is a normal stop, not a failure.
        if (message == 'interrupted' || message == 'canceled') {
          if (_started) _finish(SpeechOutcome.stopped);
          return;
        }
        debugPrint('Text-to-speech error: $message');
        _finish(SpeechOutcome.failed);
      });
      _tts.setProgressHandler((text, start, end, word) => _onProgress?.call(start, end));

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Play even when the phone's silent switch is on.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.duckOthers],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      }
      await _tts.setLanguage('en-US');
      // A touch slower than normal so young readers can follow along.
      // The web uses a different scale (1.0 = normal) from Android/iOS (0.5).
      await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      return true;
    } catch (e) {
      debugPrint('Text-to-speech is not available: $e');
      return false;
    }
  }

  /// On the web, flutter_tts ignores `speak` until the browser has confirmed
  /// the previous `stop`, so wait this long after stopping before speaking.
  static const _webSettleTime = Duration(milliseconds: 250);
  DateTime? _stoppedAt;

  @override
  Future<SpeechOutcome> speak(String text, {SpeechProgressCallback? onProgress}) async {
    if (!await (_ready ??= _init())) return SpeechOutcome.failed;

    final stoppedAt = _stoppedAt;
    if (kIsWeb && stoppedAt != null) {
      final wait = _webSettleTime - DateTime.now().difference(stoppedAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }

    _finish(SpeechOutcome.stopped);
    final completer = Completer<SpeechOutcome>();
    _current = completer;
    _onProgress = onProgress;
    _started = false;
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Text-to-speech could not speak: $e');
      _finish(SpeechOutcome.failed);
    }
    // With no voice installed, some platforms never report start, end or
    // error. Treat "never started" as a failure instead of waiting forever.
    Timer(startTimeout, () {
      if (!_started && identical(_current, completer)) {
        debugPrint('Text-to-speech did not start; is a voice installed?');
        _finish(SpeechOutcome.failed);
      }
    });
    return completer.future;
  }

  static const startTimeout = Duration(seconds: 4);

  @override
  Future<void> stop() async {
    _finish(SpeechOutcome.stopped);
    try {
      await _tts.stop();
      _stoppedAt = DateTime.now();
    } catch (_) {
      // Nothing to stop.
    }
  }

  void _finish(SpeechOutcome outcome) {
    final completer = _current;
    if (completer == null) return;
    _current = null;
    _onProgress = null;
    if (!completer.isCompleted) completer.complete(outcome);
  }

  @override
  void dispose() {
    stop();
  }
}

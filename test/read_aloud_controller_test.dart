import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/services/speech_service.dart';
import 'package:red/ui/features/session/view_models/read_aloud_controller.dart';

/// A voice that only "finishes" when the test says so.
class FakeSpeech implements SpeechService {
  final spoken = <String>[];
  Completer<SpeechOutcome>? _pending;
  SpeechProgressCallback? progress;

  @override
  Future<SpeechOutcome> speak(String text, {SpeechProgressCallback? onProgress}) {
    spoken.add(text);
    _pending = Completer();
    progress = onProgress;
    return _pending!.future;
  }

  void finish([SpeechOutcome outcome = SpeechOutcome.completed]) {
    final pending = _pending;
    _pending = null;
    pending?.complete(outcome);
  }

  @override
  Future<void> stop() async => finish(SpeechOutcome.stopped);

  @override
  void dispose() {}
}

Future<void> flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeSpeech speech;

  setUp(() => speech = FakeSpeech());

  test('reads paragraphs in order and follows the spoken word', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['The red panda.', 'It eats bamboo.']);

    final playing = controller.play();
    await flush();
    expect(controller.isPlaying, isTrue);
    expect(speech.spoken, ['The red panda.']);
    expect(controller.highlightedWordIn(0), 0);

    speech.progress!(4, 7); // "red"
    expect(controller.highlightedWordIn(0), 1);

    speech.finish();
    await flush();
    expect(speech.spoken.last, 'It eats bamboo.');
    expect(controller.activeParagraph, 1);
    expect(controller.highlightedWordIn(0), isNull);

    speech.finish();
    await playing;
    expect(controller.isPlaying, isFalse);
    expect(controller.activeParagraph, isNull);
    expect(controller.canResume, isFalse);
  });

  test('pause keeps the place and play continues from the current word', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['One two three four.']);

    unawaited(controller.play());
    await flush();
    speech.progress!(8, 13); // "three"

    await controller.pause();
    await flush();
    expect(controller.isPlaying, isFalse);
    expect(controller.canResume, isTrue);

    unawaited(controller.play());
    await flush();
    expect(speech.spoken.last, 'three four.');
  });

  test('tapping a word pauses reading and speaks only that word', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['"Hello," said Hare.']);

    unawaited(controller.play());
    await flush();

    unawaited(controller.speakWord(0, 0));
    await flush();
    expect(controller.isPlaying, isFalse);
    expect(speech.spoken.last, 'Hello');
    expect(controller.isTapped(0, 0), isTrue);

    speech.finish();
    await flush();
    expect(controller.isTapped(0, 0), isFalse);
  });

  test('tapping another word cuts off the first so both are heard', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['Slow and steady wins.']);

    unawaited(controller.speakWord(0, 0));
    await flush();
    expect(speech.spoken.last, 'Slow');

    unawaited(controller.speakWord(0, 2));
    await flush();
    expect(speech.spoken.last, 'steady');
    expect(controller.isTapped(0, 2), isTrue);
    expect(controller.isTapped(0, 0), isFalse);
  });

  test('pressing Listen while a tapped word is speaking stops the word first', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['Slow and steady wins.']);

    unawaited(controller.speakWord(0, 1));
    await flush();
    unawaited(controller.play());
    await flush();

    expect(speech.spoken, ['and', 'Slow and steady wins.']);
    expect(controller.isPlaying, isTrue);
  });

  test('a voice failure is reported instead of looping', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['One.', 'Two.']);

    unawaited(controller.play());
    await flush();
    speech.finish(SpeechOutcome.failed);
    await flush();

    expect(controller.isUnavailable, isTrue);
    expect(controller.isPlaying, isFalse);
    expect(speech.spoken, ['One.']);
  });

  test('stop goes back to the beginning', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['One.', 'Two.']);

    unawaited(controller.play());
    await flush();
    speech.finish();
    await flush();
    await controller.stop();
    await flush();

    expect(controller.canResume, isFalse);
    expect(controller.activeParagraph, isNull);
    unawaited(controller.play());
    await flush();
    expect(speech.spoken.last, 'One.');
  });

  test('a hiccup after the voice has worked does not disable read-aloud', () async {
    final controller = ReadAloudController(speech: speech, paragraphs: ['One.', 'Two.']);

    unawaited(controller.play());
    await flush();
    speech.finish(); // "One." was read fine.
    await flush();
    speech.finish(SpeechOutcome.failed);
    await flush();

    expect(controller.isUnavailable, isFalse);
    expect(controller.isPlaying, isFalse);
    expect(controller.canResume, isTrue, reason: 'Listen again continues from "Two."');

    unawaited(controller.speakWord(0, 0));
    await flush();
    expect(speech.spoken.last, 'One');
  });
}

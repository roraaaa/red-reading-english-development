import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/services/speech_service.dart';

void main() {
  test('a full stop after a day or month abbreviation becomes a comma', () {
    expect(
      SpeechText.forSpeech('Mars is the fourth planet from the Sun. When you look at it'),
      'Mars is the fourth planet from the Sun, When you look at it',
    );
    expect(SpeechText.forSpeech('We rested on Sat. Then we walked.'), 'We rested on Sat, Then we walked.');
    expect(SpeechText.forSpeech('It ends in Dec.'), 'It ends in Dec,');
  });

  test('the spoken text is always the same length, so highlighting stays in step', () {
    const samples = [
      'Mars is the fourth planet from the Sun. It looks orange-red.',
      'Plants need sunlight, and the Sun keeps our planet warm.',
      'The Sun is a giant ball of very hot, glowing gas.',
    ];
    for (final sample in samples) {
      expect(SpeechText.forSpeech(sample).length, sample.length, reason: sample);
    }
  });

  test('ordinary words and mid-sentence uses are left alone', () {
    const untouched = [
      'The Sun is the star closest to Earth.',
      'Sunlight reaches Earth in about eight minutes.',
      'A sunny day in Sunderland.',
      'Every morning, the Sun rises and lights up our day.',
    ];
    for (final sample in untouched) {
      expect(SpeechText.forSpeech(sample), sample, reason: sample);
    }
  });
}

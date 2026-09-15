import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/use_cases/word_splitter.dart';

void main() {
  test('splits words and keeps their character ranges', () {
    const text = 'Hi, Tortoise!  "Go."';
    final words = WordSplitter.split(text);

    expect(words.map((w) => w.text), ['Hi,', 'Tortoise!', '"Go."']);
    expect(words.map((w) => text.substring(w.start, w.end)), ['Hi,', 'Tortoise!', '"Go."']);
  });

  test('spoken form drops only surrounding punctuation', () {
    String spoken(String word) => WordSplitter.split(word).single.spoken;

    expect(spoken('"Hello,"'), 'Hello');
    expect(spoken('back-and-forth,'), 'back-and-forth');
    expect(spoken('2,460'), '2,460');
    expect(spoken('José'), 'José');
    expect(spoken('Mars\''), 'Mars');
  });

  test('indexAt maps a character offset to a word', () {
    final words = WordSplitter.split('One two three');

    expect(WordSplitter.indexAt(words, 0), 0);
    expect(WordSplitter.indexAt(words, 5), 1);
    expect(WordSplitter.indexAt(words, 3), 1, reason: 'a space belongs to the next word');
    expect(WordSplitter.indexAt(words, 99), 2);
    expect(WordSplitter.indexAt(const [], 0), isNull);
  });
}

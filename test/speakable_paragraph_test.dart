import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red/domain/use_cases/word_splitter.dart';
import 'package:red/ui/features/session/views/speakable_paragraph.dart';

void main() {
  const text = 'Red pandas eat bamboo.';
  final words = WordSplitter.split(text);

  Widget paragraph({int? highlight, required List<int> tapped}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SpeakableParagraph(
          text: text,
          words: words,
          style: const TextStyle(fontSize: 24),
          highlightedWord: highlight,
          onWordTap: tapped.add,
        ),
      ),
    ),
  );

  Offset centerOfWord(WidgetTester tester, int index) {
    final render = tester.renderObject<RenderParagraph>(find.byType(RichText));
    final box = render
        .getBoxesForSelection(TextSelection(baseOffset: words[index].start, extentOffset: words[index].end))
        .first;
    return render.localToGlobal(box.toRect().center);
  }

  testWidgets('tapping a word reports which word it was', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(paragraph(tapped: tapped));

    await tester.tapAt(centerOfWord(tester, 3));
    await tester.tapAt(centerOfWord(tester, 0));

    expect(tapped, [3, 0]);
  });

  testWidgets('a tap still counts when read-aloud moves the highlight mid-tap', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(paragraph(tapped: tapped, highlight: 0));

    final gesture = await tester.startGesture(centerOfWord(tester, 2));
    await tester.pumpWidget(paragraph(tapped: tapped, highlight: 1));
    await gesture.up();

    expect(tapped, [2]);
  });

  testWidgets('shows the whole paragraph to screen readers as one label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(paragraph(tapped: []));

    expect(find.bySemanticsLabel(text), findsOneWidget);
    handle.dispose();
  });
}

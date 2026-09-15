import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../domain/use_cases/word_splitter.dart';

/// A paragraph whose words can be tapped to hear them, with the word being
/// read aloud highlighted.
///
/// Taps are handled once for the whole paragraph and mapped to a word using
/// the text layout, so a tap still lands while read-aloud keeps moving the
/// highlight (per-word span recognizers were missing those taps).
class SpeakableParagraph extends StatefulWidget {
  const SpeakableParagraph({
    super.key,
    required this.text,
    required this.words,
    required this.style,
    required this.onWordTap,
    this.highlightedWord,
    this.isActive = false,
  });

  final String text;
  final List<WordToken> words;
  final TextStyle style;
  final ValueChanged<int> onWordTap;
  final int? highlightedWord;

  /// True while this paragraph is being read aloud.
  final bool isActive;

  static const highlightColor = Color(0xFFFFD66B);
  static const activeParagraphColor = Color(0xFFFFF4D6);

  @override
  State<SpeakableParagraph> createState() => _SpeakableParagraphState();
}

class _SpeakableParagraphState extends State<SpeakableParagraph> {
  final _textKey = GlobalKey();

  void _handleTapUp(TapUpDetails details) {
    final paragraph = _textKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return;
    final local = paragraph.globalToLocal(details.globalPosition);
    final offset = paragraph.getPositionForOffset(local).offset;

    for (var i = 0; i < widget.words.length; i++) {
      final word = widget.words[i];
      if (offset < word.start || offset > word.end) continue;
      // Make sure the tap is on the word itself, not blank space next to it.
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      );
      if (boxes.any((box) => box.toRect().inflate(3).contains(local))) {
        widget.onWordTap(i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < widget.words.length; i++) {
      final word = widget.words[i];
      if (word.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, word.start)));
      }
      spans.add(
        TextSpan(
          text: word.text,
          style: i == widget.highlightedWord
              ? const TextStyle(backgroundColor: SpeakableParagraph.highlightColor)
              : null,
        ),
      );
      cursor = word.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    // Screen readers get the paragraph as one block instead of every word;
    // the Listen button reads it aloud for everyone.
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isActive ? SpeakableParagraph.activeParagraphColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapUp: _handleTapUp,
            child: RichText(
              key: _textKey,
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(style: widget.style, children: spans),
            ),
          ),
        ),
      ),
    );
  }
}

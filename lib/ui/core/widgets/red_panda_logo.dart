import 'package:flutter/material.dart';

/// The RED mascot. Uses assets/images/red_panda.png when it exists and
/// falls back to a simple drawn red panda otherwise.
class RedPandaLogo extends StatelessWidget {
  const RedPandaLogo({super.key, this.size = 120, this.semanticLabel = 'RED the red panda'});

  static const assetPath = 'assets/images/red_panda.png';

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (context, error, stackTrace) => Semantics(
        label: semanticLabel,
        image: true,
        excludeSemantics: semanticLabel == null,
        child: CustomPaint(size: Size.square(size), painter: RedPandaPainter()),
      ),
    );
  }
}

/// Draws the RED mascot. Public so `tool/generate_logo_test.dart` can render
/// the same artwork to PNG files for the app and launcher icons.
class RedPandaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Paint fill(Color c) => Paint()..color = c;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect oval(double cx, double cy, double w, double h) =>
        Rect.fromCenter(center: p(cx, cy), width: w * s, height: h * s);

    const fur = Color(0xFFE0612F);
    const furDark = Color(0xFF6B2A17);
    const cream = Color(0xFFFFF6EC);
    const ink = Color(0xFF2A1A14);

    // Ears
    for (final x in [20.0, 80.0]) {
      canvas.drawCircle(p(x, 28), 17 * s, fill(furDark));
      canvas.drawCircle(p(x, 29), 9 * s, fill(cream));
    }
    // Head
    canvas.drawOval(oval(50, 56, 80, 66), fill(fur));
    // Cheeks and muzzle
    canvas.drawOval(oval(27, 64, 22, 18), fill(cream));
    canvas.drawOval(oval(73, 64, 22, 18), fill(cream));
    canvas.drawOval(oval(50, 72, 34, 22), fill(cream));
    // Eyebrow spots
    canvas.drawOval(oval(37, 40, 11, 8), fill(cream));
    canvas.drawOval(oval(63, 40, 11, 8), fill(cream));
    // Tear marks
    canvas.drawOval(oval(36, 58, 12, 18), fill(const Color(0xFFA63D1C)));
    canvas.drawOval(oval(64, 58, 12, 18), fill(const Color(0xFFA63D1C)));
    // Eyes
    canvas.drawCircle(p(37, 53), 6.5 * s, fill(ink));
    canvas.drawCircle(p(63, 53), 6.5 * s, fill(ink));
    canvas.drawCircle(p(39, 51), 2.2 * s, fill(Colors.white));
    canvas.drawCircle(p(65, 51), 2.2 * s, fill(Colors.white));
    // Nose
    canvas.drawOval(oval(50, 66, 12, 8), fill(ink));
    // Smile
    final smile = Path()
      ..moveTo(44 * s, 72 * s)
      ..quadraticBezierTo(50 * s, 78 * s, 56 * s, 72 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

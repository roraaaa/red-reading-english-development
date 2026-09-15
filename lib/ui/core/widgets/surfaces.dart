import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_icons.dart';

/// Keeps content at a comfortable reading width on tablets and the web.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    this.borderColor = AppColors.outline,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0x0F2A2340), blurRadius: 18, offset: Offset(0, 6))],
    ),
    child: child,
  );
}

/// Soft coloured blobs behind a screen. Purely decorative.
class BlobBackground extends StatelessWidget {
  const BlobBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: _BlobPainter()))),
      child,
    ],
  );
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 1.05, h * 0.02), w * 0.45, Paint()..color = const Color(0x33FFC83D));
    canvas.drawCircle(Offset(-w * 0.15, h * 0.35), w * 0.35, Paint()..color = const Color(0x1FCC3F28));
    canvas.drawCircle(Offset(w * 0.95, h * 0.85), w * 0.4, Paint()..color = const Color(0x1F2E9E6A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustrated header for a topic card: a gradient with a big icon and
/// playful circles.
class TopicCover extends StatelessWidget {
  const TopicCover({
    super.key,
    required this.icon,
    required this.color,
    this.height = 160,
    this.radius = 28,
    this.iconSize,
  });

  final String icon;
  final Color color;
  final double height;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(color, Colors.white, 0.25)!;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, color.edge],
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: -height * 0.2, top: -height * 0.25, child: _circle(height * 0.8, 0.14)),
                Positioned(left: -height * 0.15, bottom: -height * 0.35, child: _circle(height * 0.7, 0.10)),
                Positioned(left: height * 0.2, top: height * 0.12, child: _circle(height * 0.08, 0.35)),
                Center(
                  child: Icon(AppIcons.of(icon), size: iconSize ?? height * 0.5, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

/// A thick rounded progress bar.
class ChunkyProgressBar extends StatelessWidget {
  const ChunkyProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 12,
    this.semanticsLabel,
  });

  final double value;
  final Color color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            color: color,
            backgroundColor: color.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}

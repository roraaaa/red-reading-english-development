import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animations.dart';

class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.max = 3,
    this.size = 22,
    this.animate = false,
    this.emptyColor = const Color(0xFFE6DCD0),
  });

  final int stars;
  final int max;
  final double size;
  final bool animate;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars out of $max stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.04),
              child: _star(i),
            ),
        ],
      ),
    );
  }

  Widget _star(int index) {
    final filled = index < stars;
    // The middle star of three sits a little higher, like a podium.
    final lift = max == 3 && index == 1 && size > 40 ? size * 0.18 : 0.0;
    final icon = Transform.translate(
      offset: Offset(0, -lift),
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: filled ? AppColors.sunshine : emptyColor,
        shadows: filled && size > 40
            ? const [Shadow(color: Color(0x55E0A100), blurRadius: 12, offset: Offset(0, 4))]
            : null,
      ),
    );
    if (!animate || !filled) return icon;
    return PopIn(delay: Duration(milliseconds: 350 + index * 220), child: icon);
  }
}

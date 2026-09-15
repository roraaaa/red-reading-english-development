import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "RED" logotype with the full name underneath.
class RedWordmark extends StatelessWidget {
  const RedWordmark({super.key, this.size = 56, this.showTagline = true});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'RED, Reading English Development',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RED',
            style: AppTheme.display(size: size, color: AppColors.primary, weight: FontWeight.w700).copyWith(
              letterSpacing: size * 0.06,
              shadows: [Shadow(color: AppColors.primaryDeep.withValues(alpha: 0.35), offset: const Offset(0, 4))],
            ),
          ),
          if (showTagline)
            Text(
              'Reading English Development',
              style: AppTheme.body(size: size * 0.27, color: AppColors.inkSoft, weight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

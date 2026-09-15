import 'package:flutter/material.dart';

/// RED colour tokens. Text colours are checked for WCAG AA contrast against
/// [background] and [surface].
abstract final class AppColors {
  static const background = Color(0xFFFFF7EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFFBEFE3);
  static const outline = Color(0xFFEADBCB);

  static const ink = Color(0xFF2A2340);
  static const inkSoft = Color(0xFF625B75);

  /// Red panda red. White text on it is 4.9:1.
  static const primary = Color(0xFFCC3F28);
  static const primaryDeep = Color(0xFF9E2E1B);
  static const primaryTint = Color(0xFFFFE3DA);

  static const sunshine = Color(0xFFFFC83D);
  static const sunshineDeep = Color(0xFFE0A100);

  static const leaf = Color(0xFF2E9E6A);
  static const leafDeep = Color(0xFF17714A);
  static const leafTint = Color(0xFFDDF4E8);

  static const correct = Color(0xFF17804F);
  static const correctTint = Color(0xFFE0F5EA);
  static const wrong = Color(0xFFC62F2F);
  static const wrongTint = Color(0xFFFDE4E1);

  // Feature card gradients; white text stays above 4.5:1 across both ends.
  static const assessStart = Color(0xFFCC3F28);
  static const assessEnd = Color(0xFFA5301C);
  static const materialsStart = Color(0xFF17804F);
  static const materialsEnd = Color(0xFF1F6F9A);
}

import 'package:flutter/material.dart';

/// Maps the icon keys used in assets/content/*.json to Material icons.
abstract final class AppIcons {
  static const _icons = <String, IconData>{
    'leaf': Icons.eco_rounded,
    'cloud': Icons.cloud_rounded,
    'water': Icons.water_rounded,
    'diamond': Icons.diamond_rounded,
    'flower': Icons.local_florist_rounded,
    'pets': Icons.pets_rounded,
    'trophy': Icons.emoji_events_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'bee': Icons.emoji_nature_rounded,
    'egg': Icons.egg_rounded,
    'volcano': Icons.volcano_rounded,
    'drop': Icons.water_drop_rounded,
    'sparkle': Icons.auto_awesome_rounded,
    'sun': Icons.wb_sunny_rounded,
    'castle': Icons.castle_rounded,
    'sprout': Icons.grass_rounded,
    'reef': Icons.scuba_diving_rounded,
    'hearing': Icons.hearing_rounded,
    'book': Icons.menu_book_rounded,
    'waves': Icons.waves_rounded,
    'moon': Icons.nightlight_round,
    'church': Icons.church_rounded,
    'forest': Icons.forest_rounded,
    'museum': Icons.museum_rounded,
    'park': Icons.park_rounded,
    'fire': Icons.local_fire_department_rounded,
    'agriculture': Icons.agriculture_rounded,
    'rainbow': Icons.looks_rounded,
    'snow': Icons.ac_unit_rounded,
    'smile': Icons.sentiment_very_satisfied_rounded,
    'bus': Icons.directions_bus_rounded,
    'eye': Icons.visibility_rounded,
    'shield': Icons.health_and_safety_rounded,
    'spa': Icons.spa_rounded,
    'flight': Icons.flight_rounded,
    'recycle': Icons.recycling_rounded,
    'heart': Icons.favorite_rounded,
    'sailing': Icons.sailing_rounded,
    'vaccine': Icons.vaccines_rounded,
    'print': Icons.print_rounded,
    'bed': Icons.bedtime_rounded,
    'galaxy': Icons.blur_circular_rounded,
    'flag': Icons.flag_rounded,
    'bubbles': Icons.bubble_chart_rounded,
    'bug': Icons.bug_report_rounded,
    'hand': Icons.back_hand_rounded,
    'landscape': Icons.landscape_rounded,
    'terrain': Icons.terrain_rounded,
    'compass': Icons.explore_rounded,
    'tree': Icons.nature_rounded,
    'bird': Icons.flutter_dash_rounded,
    'bone': Icons.accessibility_new_rounded,
    'bolt': Icons.bolt_rounded,
    'healing': Icons.healing_rounded,
    'science': Icons.biotech_rounded,
    'pyramid': Icons.change_history_rounded,
    'robot': Icons.smart_toy_rounded,
  };

  static IconData of(String key) => _icons[key] ?? Icons.auto_stories_rounded;
}

extension ColorShades on Color {
  /// A dark shade of this colour that is readable as text on [tint].
  Color get deep {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(0.27).withSaturation((hsl.saturation * 0.9).clamp(0, 1)).toColor();
  }

  /// A very light background version of this colour.
  Color get tint => Color.lerp(Colors.white, this, 0.14)!;

  /// Slightly darker, for the bottom edge of chunky buttons and cards.
  Color get edge {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0, 1)).toColor();
  }
}

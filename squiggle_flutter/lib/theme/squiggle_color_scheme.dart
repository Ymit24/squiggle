import 'package:flutter/material.dart';

// Neutral graphite UI palette with a restrained blue-gray interaction accent.
const squiggleBaseColor = Color(0xFF171717);
const squiggleMantleColor = Color(0xFF111111);
const squiggleSurface0Color = Color(0xFF242424);
const squiggleSurface1Color = Color(0xFF363636);
const squiggleSubtext0Color = Color(0xFFA0A0A0);
const squiggleTextColor = Color(0xFFE4E4E4);
const squiggleAccentColor = Color(0xFFA8B3C2);
const squiggleSelectionFillColor = Color(0x1AA8B3C2);
const squiggleDangerColor = Color.fromARGB(255, 242, 139, 139);
const squiggleOnDangerColor = Color.fromARGB(255, 217, 95, 95);

const squiggleLightBaseColor = Color(0xFFF7F7F7);
const squiggleLightMantleColor = Color(0xFFEEEEEE);
const squiggleLightSurface0Color = Color(0xFFE2E2E2);
const squiggleLightSurface1Color = Color(0xFFCCCCCC);
const squiggleLightSubtext0Color = Color(0xFF5F5F5F);
const squiggleLightTextColor = Color(0xFF1E1E1E);
const squiggleLightAccentColor = Color(0xFF3F5875);
const squiggleLightSelectionFillColor = Color(0x223F5875);
const squiggleLightDangerColor = Color(0xFFC0392B);
const squiggleLightOnDangerColor = Color(0xFFA5281B);

/// Semantic UI color tokens for Squiggle's dark graphite theme.
@immutable
class SquiggleColorScheme {
  const SquiggleColorScheme({
    required this.base,
    required this.mantle,
    required this.surface0,
    required this.surface1,
    required this.subtext0,
    required this.text,
    required this.accent,
    required this.selectionFill,
    required this.danger,
    required this.onDanger,
  });

  final Color base;
  final Color mantle;
  final Color surface0;
  final Color surface1;
  final Color subtext0;
  final Color text;
  final Color accent;
  final Color selectionFill;
  final Color danger;
  final Color onDanger;

  static const dark = SquiggleColorScheme(
    base: squiggleBaseColor,
    mantle: squiggleMantleColor,
    surface0: squiggleSurface0Color,
    surface1: squiggleSurface1Color,
    subtext0: squiggleSubtext0Color,
    text: squiggleTextColor,
    accent: squiggleAccentColor,
    selectionFill: squiggleSelectionFillColor,
    danger: squiggleDangerColor,
    onDanger: squiggleOnDangerColor,
  );

  static const light = SquiggleColorScheme(
    base: squiggleLightBaseColor,
    mantle: squiggleLightMantleColor,
    surface0: squiggleLightSurface0Color,
    surface1: squiggleLightSurface1Color,
    subtext0: squiggleLightSubtext0Color,
    text: squiggleLightTextColor,
    accent: squiggleLightAccentColor,
    selectionFill: squiggleLightSelectionFillColor,
    danger: squiggleLightDangerColor,
    onDanger: squiggleLightOnDangerColor,
  );

  SquiggleColorScheme copyWith({
    Color? base,
    Color? mantle,
    Color? surface0,
    Color? surface1,
    Color? subtext0,
    Color? text,
    Color? accent,
    Color? selectionFill,
    Color? danger,
    Color? onDanger,
  }) {
    return SquiggleColorScheme(
      base: base ?? this.base,
      mantle: mantle ?? this.mantle,
      surface0: surface0 ?? this.surface0,
      surface1: surface1 ?? this.surface1,
      subtext0: subtext0 ?? this.subtext0,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      selectionFill: selectionFill ?? this.selectionFill,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  SquiggleColorScheme lerp(SquiggleColorScheme other, double t) {
    return SquiggleColorScheme(
      base: Color.lerp(base, other.base, t)!,
      mantle: Color.lerp(mantle, other.mantle, t)!,
      surface0: Color.lerp(surface0, other.surface0, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      subtext0: Color.lerp(subtext0, other.subtext0, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      selectionFill: Color.lerp(selectionFill, other.selectionFill, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

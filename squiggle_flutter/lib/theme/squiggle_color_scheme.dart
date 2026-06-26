import 'package:flutter/material.dart';

const squiggleBaseColor = Color(0xFF1E1E2E);
const squiggleMantleColor = Color(0xFF181825);
const squiggleSurface0Color = Color(0xFF313244);
const squiggleSurface1Color = Color(0xFF45475A);
const squiggleSubtext0Color = Color(0xFFA6ADC8);
const squiggleTextColor = Color(0xFFCDD6F4);
const squiggleAccentColor = Color(0xFF89B4FA);
const squiggleScrimColor = Color(0x33000000);
const squiggleSelectionFillColor = Color(0x0F89B4FA);

/// Semantic UI color tokens (Catppuccin Mocha, matches rust-version `colors.rs`).
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
    required this.scrim,
    required this.selectionFill,
  });

  final Color base;
  final Color mantle;
  final Color surface0;
  final Color surface1;
  final Color subtext0;
  final Color text;
  final Color accent;
  final Color scrim;
  final Color selectionFill;

  static const dark = SquiggleColorScheme(
    base: squiggleBaseColor,
    mantle: squiggleMantleColor,
    surface0: squiggleSurface0Color,
    surface1: squiggleSurface1Color,
    subtext0: squiggleSubtext0Color,
    text: squiggleTextColor,
    accent: squiggleAccentColor,
    scrim: squiggleScrimColor,
    selectionFill: squiggleSelectionFillColor,
  );

  SquiggleColorScheme copyWith({
    Color? base,
    Color? mantle,
    Color? surface0,
    Color? surface1,
    Color? subtext0,
    Color? text,
    Color? accent,
    Color? scrim,
    Color? selectionFill,
  }) {
    return SquiggleColorScheme(
      base: base ?? this.base,
      mantle: mantle ?? this.mantle,
      surface0: surface0 ?? this.surface0,
      surface1: surface1 ?? this.surface1,
      subtext0: subtext0 ?? this.subtext0,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      scrim: scrim ?? this.scrim,
      selectionFill: selectionFill ?? this.selectionFill,
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
      scrim: Color.lerp(scrim, other.scrim, t)!,
      selectionFill: Color.lerp(selectionFill, other.selectionFill, t)!,
    );
  }
}

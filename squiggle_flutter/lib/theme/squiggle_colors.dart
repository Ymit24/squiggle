import 'package:flutter/material.dart';

import 'squiggle_color_scheme.dart';

/// Convenience accessors for Squiggle UI colors outside of [BuildContext].
///
/// Prefer [SquiggleTheme] via `context.squiggleTheme` in widgets.
abstract final class SquiggleColors {
  static const base = squiggleBaseColor;
  static const mantle = squiggleMantleColor;
  static const surface0 = squiggleSurface0Color;
  static const surface1 = squiggleSurface1Color;
  static const subtext0 = squiggleSubtext0Color;
  static const text = squiggleTextColor;
  static const accent = squiggleAccentColor;
  static const scrim = squiggleScrimColor;
  static const selectionFill = squiggleSelectionFillColor;
}

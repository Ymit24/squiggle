import 'package:flutter/material.dart';

import 'squiggle_color_scheme.dart';
import 'squiggle_decorations.dart';
import 'squiggle_radii.dart';
import 'squiggle_spacing.dart';
import 'squiggle_typography.dart';

/// Central theme extension bundling Squiggle UI tokens.
@immutable
class SquiggleTheme extends ThemeExtension<SquiggleTheme> {
  const SquiggleTheme({
    required this.colors,
    required this.spacing,
    required this.radii,
    required this.typography,
    required this.decorations,
  });

  final SquiggleColorScheme colors;
  final SquiggleSpacing spacing;
  final SquiggleRadii radii;
  final SquiggleTypography typography;
  final SquiggleDecorations decorations;

  static final dark = SquiggleTheme(
    colors: SquiggleColorScheme.dark,
    spacing: SquiggleSpacing.standard,
    radii: SquiggleRadii.standard,
    typography: const SquiggleTypography(colors: SquiggleColorScheme.dark),
    decorations: const SquiggleDecorations(
      colors: SquiggleColorScheme.dark,
      radii: SquiggleRadii.standard,
    ),
  );

  @override
  SquiggleTheme copyWith({
    SquiggleColorScheme? colors,
    SquiggleSpacing? spacing,
    SquiggleRadii? radii,
    SquiggleTypography? typography,
    SquiggleDecorations? decorations,
  }) {
    final nextColors = colors ?? this.colors;
    return SquiggleTheme(
      colors: nextColors,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      typography: typography ?? this.typography.copyWith(colors: nextColors),
      decorations:
          decorations ??
          this.decorations.copyWith(colors: nextColors, radii: radii ?? this.radii),
    );
  }

  @override
  SquiggleTheme lerp(ThemeExtension<SquiggleTheme>? other, double t) {
    if (other is! SquiggleTheme) return this;
    return SquiggleTheme(
      colors: colors.lerp(other.colors, t),
      spacing: spacing.lerp(other.spacing, t),
      radii: radii.lerp(other.radii, t),
      typography: typography.lerp(other.typography, t),
      decorations: decorations.lerp(other.decorations, t),
    );
  }
}

/// Builds a [ThemeData] wired to [SquiggleTheme].
abstract final class SquiggleThemeData {
  static ThemeData dark() {
    final squiggle = SquiggleTheme.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: squiggle.colors.base,
      colorScheme: ColorScheme.dark(
        surface: squiggle.colors.base,
        onSurface: squiggle.colors.text,
        primary: squiggle.colors.accent,
        onPrimary: squiggle.colors.base,
        outline: squiggle.colors.surface1,
      ),
      extensions: [squiggle],
    );
  }
}

extension SquiggleThemeContext on BuildContext {
  SquiggleTheme get squiggleTheme =>
      Theme.of(this).extension<SquiggleTheme>() ?? SquiggleTheme.dark;
}

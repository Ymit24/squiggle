import 'package:flutter/material.dart';

import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_decorations.dart';
import 'package:squiggle_flutter/theme/squiggle_radii.dart';
import 'package:squiggle_flutter/theme/squiggle_motion.dart';
import 'package:squiggle_flutter/theme/squiggle_spacing.dart';
import 'package:squiggle_flutter/theme/squiggle_typography.dart';

/// Central theme extension bundling Squiggle UI tokens.
@immutable
class SquiggleTheme extends ThemeExtension<SquiggleTheme> {
  const SquiggleTheme({
    required this.colors,
    required this.spacing,
    required this.radii,
    required this.typography,
    required this.decorations,
    required this.motion,
  });

  final SquiggleColorScheme colors;
  final SquiggleSpacing spacing;
  final SquiggleRadii radii;
  final SquiggleTypography typography;
  final SquiggleDecorations decorations;
  final SquiggleMotion motion;

  static final dark = SquiggleTheme(
    colors: SquiggleColorScheme.dark,
    spacing: SquiggleSpacing.standard,
    radii: SquiggleRadii.standard,
    typography: const SquiggleTypography(colors: SquiggleColorScheme.dark),
    decorations: const SquiggleDecorations(
      colors: SquiggleColorScheme.dark,
      radii: SquiggleRadii.standard,
    ),
    motion: SquiggleMotion.standardMotion,
  );

  @override
  SquiggleTheme copyWith({
    SquiggleColorScheme? colors,
    SquiggleSpacing? spacing,
    SquiggleRadii? radii,
    SquiggleTypography? typography,
    SquiggleDecorations? decorations,
    SquiggleMotion? motion,
  }) {
    final nextColors = colors ?? this.colors;
    return SquiggleTheme(
      colors: nextColors,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      typography: typography ?? this.typography.copyWith(colors: nextColors),
      decorations:
          decorations ??
          this.decorations.copyWith(
            colors: nextColors,
            radii: radii ?? this.radii,
          ),
      motion: motion ?? this.motion,
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
      motion: motion.lerp(other.motion, t),
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
        error: squiggle.colors.dangerStrong,
        onError: squiggle.colors.onDanger,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: squiggle.colors.base,
        shape: squiggle.decorations.dialogShape(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: squiggle.colors.subtext0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(squiggle.radii.action),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: squiggle.colors.text,
          foregroundColor: squiggle.colors.base,
          disabledBackgroundColor: squiggle.colors.surface0,
          disabledForegroundColor: squiggle.colors.subtext0.withValues(
            alpha: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(squiggle.radii.action),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      extensions: [squiggle],
    );
  }
}

extension SquiggleThemeContext on BuildContext {
  SquiggleTheme get squiggleTheme =>
      Theme.of(this).extension<SquiggleTheme>() ?? SquiggleTheme.dark;
}

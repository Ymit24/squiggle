import 'package:flutter/material.dart';

import 'squiggle_color_scheme.dart';

/// Text style presets for UI chrome.
@immutable
class SquiggleTypography {
  const SquiggleTypography({required this.colors});

  final SquiggleColorScheme colors;

  TextStyle get sectionLabel => TextStyle(
    color: colors.subtext0,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  TextStyle get hotkey => TextStyle(
    color: colors.subtext0,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  TextStyle buttonLabel({required bool isActive}) => TextStyle(
    color: isActive ? colors.text : colors.subtext0,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  TextStyle get inputText => TextStyle(
    color: colors.text,
    fontSize: 14,
  );

  TextStyle panelButtonLabel({required bool isPrimary}) => TextStyle(
    color: isPrimary ? colors.base : colors.text,
    fontSize: 13,
    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
  );

  TextStyle swatchOverlayLabel({
    required bool isActive,
    required double fontSize,
  }) => TextStyle(
    color: isActive ? colors.text : colors.subtext0,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    height: 1,
  );

  SquiggleTypography copyWith({SquiggleColorScheme? colors}) {
    return SquiggleTypography(colors: colors ?? this.colors);
  }

  SquiggleTypography lerp(SquiggleTypography other, double t) {
    return SquiggleTypography(
      colors: colors.lerp(other.colors, t),
    );
  }
}

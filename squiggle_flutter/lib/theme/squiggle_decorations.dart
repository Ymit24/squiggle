import 'package:flutter/material.dart';

import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_radii.dart';

/// Shared [BoxDecoration] and [InputDecoration] builders for UI chrome.
@immutable
class SquiggleDecorations {
  const SquiggleDecorations({required this.colors, required this.radii});

  final SquiggleColorScheme colors;
  final SquiggleRadii radii;

  BoxDecoration floatingPanel() => BoxDecoration(
    color: colors.mantle,
    border: Border.all(color: colors.surface1),
    borderRadius: BorderRadius.circular(radii.floatingPanel),
  );

  BoxDecoration textEditPanel() => BoxDecoration(
    border: Border.all(color: colors.surface1),
    borderRadius: BorderRadius.circular(radii.textEditPanel),
  );

  BoxDecoration toolbarButton({
    required bool isActive,
    required bool isHovering,
  }) => BoxDecoration(
    color: _toolbarButtonColor(isActive, isHovering),
    borderRadius: BorderRadius.circular(radii.button),
  );

  BoxDecoration panelButton({
    required bool isPrimary,
    required bool isHovering,
  }) => BoxDecoration(
    color: _panelButtonColor(isPrimary, isHovering),
    borderRadius: BorderRadius.circular(radii.button),
  );

  InputDecoration textField() => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: colors.surface0,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.surface1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.surface1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.input),
      borderSide: BorderSide(color: colors.accent),
    ),
  );

  SquiggleDecorations copyWith({
    SquiggleColorScheme? colors,
    SquiggleRadii? radii,
  }) {
    return SquiggleDecorations(
      colors: colors ?? this.colors,
      radii: radii ?? this.radii,
    );
  }

  SquiggleDecorations lerp(SquiggleDecorations other, double t) {
    return SquiggleDecorations(
      colors: colors.lerp(other.colors, t),
      radii: radii.lerp(other.radii, t),
    );
  }

  Color? _toolbarButtonColor(bool isActive, bool isHovering) {
    if (isActive) {
      return colors.surface1;
    }
    if (isHovering) {
      return colors.surface0;
    }
    return null;
  }

  Color _panelButtonColor(bool isPrimary, bool isHovering) {
    if (isPrimary) {
      if (isHovering) {
        return colors.accent.withValues(alpha: 0.85);
      }
      return colors.accent.withValues(alpha: 1);
    }
    if (isHovering) {
      return colors.surface0;
    }
    return colors.surface1;
  }
}

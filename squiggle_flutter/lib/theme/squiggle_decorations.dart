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
    color: isActive ? colors.surface1 : (isHovering ? colors.surface0 : null),
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

  InputDecoration libraryTextField({EdgeInsetsGeometry? contentPadding}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.control),
      borderSide: BorderSide(color: colors.surface1),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: colors.surface0,
      contentPadding: contentPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: colors.accent.withValues(alpha: 0.7),
          width: 1.4,
        ),
      ),
    );
  }

  RoundedRectangleBorder dialogShape() => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.card),
    side: BorderSide(color: colors.surface1),
  );

  RoundedRectangleBorder menuShape() => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.floatingPanel),
    side: BorderSide(color: colors.surface1),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_decorations.dart';
import 'package:squiggle_flutter/theme/squiggle_radii.dart';

void main() {
  final colors = SquiggleColorScheme.dark.copyWith(
    accent: const Color(0x40A8B3C2),
  );
  final decorations = SquiggleDecorations(
    colors: colors,
    radii: SquiggleRadii.standard,
  );

  test('primary panel buttons set opacity even with a translucent accent', () {
    expect(
      decorations.panelButton(isPrimary: true, isHovering: false).color,
      colors.accent.withValues(alpha: 1),
    );
    expect(
      decorations.panelButton(isPrimary: true, isHovering: true).color,
      colors.accent.withValues(alpha: 0.85),
    );
    expect(
      decorations.panelButton(isPrimary: false, isHovering: true).color,
      colors.surface0,
    );
    expect(
      decorations.panelButton(isPrimary: false, isHovering: false).color,
      colors.surface1,
    );
  });

  test('toolbar active styling takes precedence over hover styling', () {
    expect(
      decorations.toolbarButton(isActive: true, isHovering: true).color,
      colors.surface1,
    );
    expect(
      decorations.toolbarButton(isActive: false, isHovering: true).color,
      colors.surface0,
    );
    expect(
      decorations.toolbarButton(isActive: false, isHovering: false).color,
      isNull,
    );
  });
}

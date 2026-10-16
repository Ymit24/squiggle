import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// Names the pending change under the wheel: "Active → Hovered", the current
/// brush when it is hovered, a new brush hint, or a cancel hint when nothing is.
class BrushWheelLabel extends StatelessWidget {
  const BrushWheelLabel({
    super.key,
    required this.active,
    this.hovered,
    this.adding = false,
  });

  final BrushProfile active;
  final BrushProfile? hovered;
  final bool adding;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.mantle,
        border: Border.all(color: colors.surface1),
        borderRadius: BorderRadius.circular(BrushWheelGeometry.labelHeight / 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          widthFactor: 1,
          child: Text.rich(
            _text(TextStyle(color: colors.subtext0)),
            key: const ValueKey('brush-wheel-label'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.menuItemLabel.copyWith(
              color: colors.text,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _text(TextStyle muted) {
    if (adding) {
      return const TextSpan(text: 'New brush…');
    }

    final target = hovered;

    if (target == null) {
      return TextSpan(text: 'Release to cancel', style: muted);
    }

    if (target.id == active.id) {
      return TextSpan(
        text: target.name,
        children: [TextSpan(text: ' · current', style: muted)],
      );
    }

    return TextSpan(
      children: [
        TextSpan(text: '${active.name} → ', style: muted),
        TextSpan(text: target.name),
      ],
    );
  }
}

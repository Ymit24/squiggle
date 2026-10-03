import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/brush_preview.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/metrics.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

class BrushMenuEntry extends StatelessWidget {
  const BrushMenuEntry({
    super.key,
    required this.brush,
    required this.selected,
    required this.imageRepository,
    required this.onPressed,
    this.shortcutNumber,
    this.mouseCursor,
  });

  final BrushProfile brush;
  final bool selected;
  final ImageRepository imageRepository;
  final VoidCallback onPressed;
  final int? shortcutNumber;
  final MouseCursor? mouseCursor;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuItemButton(
          onPressed: onPressed,
          requestFocusOnHover: false,
          style: theme.menuItemStyle().copyWith(
            mouseCursor: mouseCursor == null
                ? null
                : WidgetStatePropertyAll(mouseCursor!),
            backgroundColor: selected
                ? WidgetStatePropertyAll(theme.colors.surface0)
                : null,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: theme.spacing.menuPadding,
                vertical: brushEntryVerticalPadding,
              ),
            ),
          ),
          child: SizedBox(
            // The drag proxy leaves the menu scope; keep the content bounded
            // even when MenuItemButton changes its internal row layout.
            width: constraints.maxWidth - theme.spacing.menuPadding * 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        brush.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected) const Icon(Icons.check, size: 14),
                    if (shortcutNumber != null) ...[
                      const SizedBox(width: 6),
                      SquiggleShortcutHint(label: '⌘$shortcutNumber'),
                    ],
                  ],
                ),
                const SizedBox(height: brushPreviewGap),
                BrushPreview(brush: brush, imageRepository: imageRepository),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_preview.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class BrushMenuEntry extends StatelessWidget {
  const BrushMenuEntry({
    super.key,
    required this.brush,
    required this.selected,
    required this.imageRepository,
    required this.onPressed,
    this.shortcutNumber,
  });

  final BrushProfile brush;
  final bool selected;
  final ImageRepository imageRepository;
  final VoidCallback onPressed;
  final int? shortcutNumber;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return MenuItemButton(
      onPressed: onPressed,
      requestFocusOnHover: false,
      style: theme.menuItemStyle().copyWith(
        backgroundColor: selected
            ? WidgetStatePropertyAll(theme.colors.surface0)
            : null,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        ),
      ),
      child: SizedBox(
        width: theme.spacing.menuWidth - theme.spacing.menuPadding * 2 - 12,
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
            const SizedBox(height: 3),
            BrushPreview(brush: brush, imageRepository: imageRepository),
          ],
        ),
      ),
    );
  }
}

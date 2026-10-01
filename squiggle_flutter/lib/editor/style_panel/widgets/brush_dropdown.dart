import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_controller.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_menu_entry.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_reorder_row.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/metrics.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

/// Scratch and Create remain fixed while named profiles can be reordered.
class BrushDropdown extends StatelessWidget {
  const BrushDropdown({
    super.key,
    required this.brushes,
    required this.imageRepository,
    required this.onCreate,
  });

  final BrushController brushes;
  final ImageRepository imageRepository;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final text = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(
          context,
        ).style.merge(theme.typography.menuItemLabel),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final rowHeight =
        math.max(text.height, spacing.buttonIconSize) +
        brushPreviewHeight +
        brushPreviewGap +
        brushEntryVerticalPadding * 2;
    text.dispose();
    final availableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                spacing.overlayTop * 2 -
                spacing.menuPadding * 2)
            .clamp(0.0, double.infinity);
    return ListenableBuilder(
      listenable: brushes,
      builder: (context, _) {
        final profiles = brushes.profiles;
        final scratch = profiles.first;
        final named = profiles.skip(1).toList();
        return SizedBox(
          // Explicit dimensions keep the viewport out of MenuAnchor's
          // intrinsic measurement. Only the profile list scrolls.
          width: spacing.menuWidth - spacing.menuPadding * 2,
          height: math.min(
            availableHeight,
            profiles.length * rowHeight +
                spacing.menuDividerHeight +
                spacing.menuItemHeight,
          ),
          child: Column(
            children: [
              SizedBox(
                height: rowHeight,
                child: BrushMenuEntry(
                  brush: scratch,
                  selected: scratch.id == brushes.active.id,
                  shortcutNumber: 1,
                  imageRepository: imageRepository,
                  onPressed: () => brushes.activate(scratch.id),
                ),
              ),
              if (named.isNotEmpty)
                Expanded(
                  child: ReorderableListView.builder(
                    key: const ValueKey('brush-reorder-list'),
                    primary: false,
                    itemExtent: rowHeight,
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: named.length,
                    onReorderItem: (oldIndex, newIndex) =>
                        brushes.move(named[oldIndex].id, toIndex: newIndex + 1),
                    proxyDecorator: (child, index, animation) => Material(
                      color: theme.colors.mantle,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.radii.button),
                        side: BorderSide(color: theme.colors.surface1),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grabbing,
                        child: IgnorePointer(child: child),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final brush = named[index];
                      return BrushReorderRow(
                        key: ValueKey(brush.id),
                        index: index,
                        brush: brush,
                        selected: brush.id == brushes.active.id,
                        imageRepository: imageRepository,
                        onPressed: () => brushes.activate(brush.id),
                      );
                    },
                  ),
                ),
              Divider(height: spacing.menuDividerHeight),
              SquiggleMenuItem(
                label: 'Create brush',
                icon: Icons.add,
                onPressed: brushes.canCreate ? onCreate : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

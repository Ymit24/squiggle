import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/widgets/squiggle_context_menu.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_divider.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

class ContextMenu extends StatelessWidget {
  final Offset localScreenPosition;
  final EditorContext editorContext;

  const ContextMenu({
    super.key,
    required this.localScreenPosition,
    required this.editorContext,
  });

  List<Widget> _buildMenuItems(BuildContext context) {
    final selection = editorContext.selection;

    if (selection.isEmpty) {
      return [
        SquiggleMenuItem(
          label: 'Select All',
          icon: LucideIcons.mousePointer,
          shortcut: '⌘A',
          onPressed: () {
            editorContext.selection.setSelection(
              editorContext.document.nodes.map((node) => node.id),
            );
            // dismiss the context menu
            Navigator.of(context).pop();
          },
        ),
        SquiggleMenuDivider(),

        const SquiggleMenuItem(
          label: 'Paste',
          icon: LucideIcons.clipboard,
          shortcut: '⌘V',
          onPressed: null,
        ),
      ];
    }

    return [
      SquiggleMenuItem(
        label: 'Duplicate',
        icon: LucideIcons.copy,
        shortcut: '⌘D',
        onPressed: null,
      ),
      SquiggleMenuItem(
        label: 'Copy',
        icon: LucideIcons.file,
        shortcut: '⌘C',
        onPressed: null,
      ),
      const SquiggleMenuItem(
        label: 'Paste',
        icon: LucideIcons.clipboard,
        shortcut: '⌘V',
        onPressed: null,
      ),
      const SquiggleMenuDivider(),

      SquiggleMenuItem(
        label: 'Bring backward',
        icon: LucideIcons.layers,
        shortcut: '⌘[',
        onPressed: null,
      ),
      SquiggleMenuItem(
        label: 'Bring forward',
        icon: LucideIcons.layers,
        shortcut: '⌘]',
        onPressed: null,
      ),
      SquiggleMenuItem(
        label: 'Send to Back',
        icon: LucideIcons.layers,
        shortcut: '⌘⌥[',
        onPressed: null,
      ),
      SquiggleMenuItem(
        label: 'Bring to Front',
        icon: LucideIcons.layers,
        shortcut: '⌘⌥]',
        onPressed: null,
      ),
      const SquiggleMenuDivider(),
      SquiggleMenuItem(
        label: 'Delete',
        icon: LucideIcons.trash2,
        shortcut: '⌫',
        onPressed: () {
          editorContext.history.run("Delete", (transaction) {
            transaction.removeAll(editorContext.selection.selectedNodeIds);
          });
          editorContext.selection.clearSelection();
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => SquiggleContextMenu(
    position: localScreenPosition,
    children: _buildMenuItems(context),
  );
}

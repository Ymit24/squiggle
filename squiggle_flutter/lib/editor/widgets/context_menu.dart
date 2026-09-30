import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';
import 'package:squiggle_flutter/services/paste_clipboard.dart';
import 'package:squiggle_flutter/widgets/squiggle_context_menu.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_divider.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

class ContextMenu extends StatelessWidget {
  final Offset localScreenPosition;
  final EditorContext editorContext;
  final ImageRepository imageRepository;

  const ContextMenu({
    super.key,
    required this.localScreenPosition,
    required this.editorContext,
    required this.imageRepository,
  });

  void _copy(BuildContext context, {bool cut = false}) {
    if (cut) {
      cutSelectedNodesToClipboard(
        context: editorContext,
        imageRepository: imageRepository,
      );
    } else {
      copySelectedNodesToClipboard(
        context: editorContext,
        imageRepository: imageRepository,
      );
    }
    Navigator.of(context).pop();
  }

  void _paste(BuildContext context) {
    pasteFromClipboard(
      context: editorContext,
      imageRepository: imageRepository,
    );
    Navigator.of(context).pop();
  }

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

        SquiggleMenuItem(
          label: 'Paste',
          icon: LucideIcons.clipboard,
          shortcut: '⌘V',
          onPressed: () => _paste(context),
        ),
      ];
    }

    return [
      SquiggleMenuItem(
        label: 'Cut',
        icon: LucideIcons.scissors,
        shortcut: '⌘X',
        onPressed: () => _copy(context, cut: true),
      ),
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
        onPressed: () => _copy(context),
      ),
      SquiggleMenuItem(
        label: 'Paste',
        icon: LucideIcons.clipboard,
        shortcut: '⌘V',
        onPressed: () => _paste(context),
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

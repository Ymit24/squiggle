import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_divider.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

class ContextMenu extends StatefulWidget {
  final Offset localScreenPosition;
  final EditorContext editorContext;

  const ContextMenu({
    super.key,
    required this.localScreenPosition,
    required this.editorContext,
  });

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  final GlobalKey _key = GlobalKey();

  Offset _localPosition = Offset.zero;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box =
          _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final size = box.size;
        final position = widget.localScreenPosition;
        final screenSize = MediaQuery.of(context).size;

        final padding = Offset(
          context.squiggleTheme.spacing.panelPadding,
          context.squiggleTheme.spacing.panelPadding,
        );

        final clampedScreenPosition = Offset(
          position.dx.clamp(
            padding.dx,
            screenSize.width - size.width - padding.dx,
          ),
          position.dy.clamp(
            padding.dy,
            screenSize.height - size.height - padding.dy,
          ),
        );

        setState(() {
          _localPosition = clampedScreenPosition;
          _isVisible = true;
        });
      }
    });
  }

  List<Widget> _buildMenuItems() {
    final selection = widget.editorContext.selection;

    if (selection.isEmpty) {
      return [
        SquiggleMenuItem(
          label: 'Select All',
          icon: LucideIcons.mousePointer,
          shortcut: '⌘A',
          onPressed: () {
            widget.editorContext.selection.setSelection(
              widget.editorContext.document.nodes.map((node) => node.id),
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
          widget.editorContext.history.run("Delete", (transaction) {
            transaction.removeAll(
              widget.editorContext.selection.selectedNodeIds,
            );
          });
          widget.editorContext.selection.clearSelection();
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Positioned(
      left: _localPosition.dx,
      top: _localPosition.dy,
      child: Opacity(
        opacity: _isVisible ? 1.0 : 0.0,
        child: Container(
          key: _key,
          width: theme.spacing.menuWidth,
          decoration: theme.decorations.floatingPanel(),
          padding: EdgeInsets.all(theme.spacing.menuPadding),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildMenuItems(),
            ),
          ),
        ),
      ),
    );
  }
}

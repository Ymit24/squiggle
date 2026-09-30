import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/theme.dart';
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

  Widget _divider() {
    final theme = context.squiggleTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.menuItemHorizontalPadding,
      ),
      child: Divider(
        height: theme.spacing.menuDividerHeight,
        thickness: 1,
        color: theme.colors.surface1,
      ),
    );
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
              children: [
                SquiggleMenuItem(
                  label: 'Duplicate',
                  icon: LucideIcons.copy,
                  shortcut: '⌘D',
                  onPressed: () => debugPrint('clicked DUPLICATE'),
                ),
                SquiggleMenuItem(
                  label: 'Copy',
                  icon: LucideIcons.file,
                  shortcut: '⌘C',
                  onPressed: () => debugPrint('clicked COPY'),
                ),
                const SquiggleMenuItem(
                  label: 'Paste',
                  icon: LucideIcons.clipboard,
                  shortcut: '⌘V',
                  onPressed: null,
                ),
                _divider(),
                SquiggleMenuItem(
                  label: 'Bring to Front',
                  icon: LucideIcons.layers,
                  shortcut: '⌘⇧]',
                  onPressed: () => debugPrint('clicked BRING TO FRONT'),
                ),
                SquiggleMenuItem(
                  label: 'Send to Back',
                  icon: LucideIcons.layers,
                  shortcut: '⌘⇧[',
                  onPressed: () => debugPrint('clicked SEND TO BACK'),
                ),
                _divider(),
                SquiggleMenuItem(
                  label: 'Lock',
                  icon: LucideIcons.lock,
                  shortcut: '⌘L',
                  onPressed: () => debugPrint('clicked LOCK'),
                ),
                SquiggleMenuItem(
                  label: 'Delete',
                  icon: LucideIcons.trash2,
                  shortcut: '⌫',
                  onPressed: () => debugPrint('clicked DELETE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

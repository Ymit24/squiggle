import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/theme.dart';

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

  Widget _action({
    required String label,
    required String icon,
    required String shortcut,
    bool enabled = true,
  }) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final foreground = enabled
        ? theme.colors.text
        : theme.colors.subtext0.withValues(alpha: 0.5);

    return TextButton(
      onPressed: enabled
          ? () => debugPrint('clicked ${label.toUpperCase()}')
          : null,
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          theme.typography.actionButtonLabel.copyWith(
            fontWeight: FontWeight.normal,
            letterSpacing: 0,
          ),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: spacing.buttonIconGap),
        ),
        minimumSize: WidgetStatePropertyAll(
          Size(0, spacing.toolbarButtonSize - spacing.panelLabelSpacing),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radii.button),
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)
              ? theme.colors.surface0
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/$icon.svg',
            width: spacing.buttonIconSize,
            height: spacing.buttonIconSize,
            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          ),
          SizedBox(width: spacing.panelPadding),
          Expanded(
            child: Text(
              label,
              style: theme.typography.actionButtonLabel.copyWith(
                color: foreground,
              ),
            ),
          ),
          SizedBox(width: spacing.panelLabelSpacing),
          Text(
            shortcut,
            style: theme.typography.actionButtonLabel.copyWith(
              color: enabled ? theme.colors.subtext0 : foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    final theme = context.squiggleTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.buttonIconGap),
      child: Divider(
        height: theme.spacing.panelSectionSpacing + 2,
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
          width: 188,
          decoration: theme.decorations.floatingPanel(),
          padding: EdgeInsets.all(theme.spacing.panelPadding / 2),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _action(label: 'Duplicate', icon: 'duplicate', shortcut: '⌘D'),
                _action(label: 'Copy', icon: 'copy', shortcut: '⌘C'),
                _action(
                  label: 'Paste',
                  icon: 'paste',
                  shortcut: '⌘V',
                  enabled: false,
                ),
                _divider(),
                _action(
                  label: 'Bring to Front',
                  icon: 'layers',
                  shortcut: '⌘⇧]',
                ),
                _action(label: 'Send to Back', icon: 'layers', shortcut: '⌘⇧['),
                _divider(),
                _action(label: 'Lock', icon: 'lock', shortcut: '⌘L'),
                _action(label: 'Delete', icon: 'delete', shortcut: '⌫'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

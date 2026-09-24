import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

typedef _MenuEntry = ({
  String label,
  IconData icon,
  String? shortcut,
  bool danger,
  bool sectionBefore,
});

const _entries = <_MenuEntry>[
  (label: 'Cut', icon: Icons.content_cut_rounded, shortcut: '⌘X', danger: false, sectionBefore: false),
  (label: 'Copy', icon: Icons.content_copy_rounded, shortcut: '⌘C', danger: false, sectionBefore: false),
  (label: 'Paste', icon: Icons.content_paste_rounded, shortcut: '⌘V', danger: false, sectionBefore: false),
  (label: 'Bring to front', icon: Icons.vertical_align_top_rounded, shortcut: null, danger: false, sectionBefore: true),
  (label: 'Bring forward', icon: Icons.arrow_upward_rounded, shortcut: null, danger: false, sectionBefore: false),
  (label: 'Send backward', icon: Icons.arrow_downward_rounded, shortcut: null, danger: false, sectionBefore: false),
  (label: 'Send to back', icon: Icons.vertical_align_bottom_rounded, shortcut: null, danger: false, sectionBefore: false),
  (label: 'Group', icon: Icons.group_rounded, shortcut: '⌘G', danger: false, sectionBefore: true),
  (label: 'Ungroup', icon: Icons.group_off_rounded, shortcut: null, danger: false, sectionBefore: false),
  (label: 'Delete', icon: Icons.delete_outline_rounded, shortcut: '⌫', danger: true, sectionBefore: true),
];

class ContextMenu extends StatefulWidget {
  final ContextMenuState state;

  const ContextMenu({super.key, required this.state});

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final typography = theme.typography;

    final selectionCount = widget.state.selectedNodeIds.length;
    final headerLabel = selectionCount == 0
        ? 'Canvas'
        : '$selectionCount selected';

    return Positioned(
      left: widget.state.localScreenPosition.dx,
      top: widget.state.localScreenPosition.dy,
      child: SizedBox(
        width: spacing.menuWidth,
        child: DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: Padding(
            padding: EdgeInsets.all(spacing.toolbarPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: spacing.toolbarGap,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.panelPadding,
                    vertical: spacing.panelLabelSpacing,
                  ),
                  child: Text(headerLabel, style: typography.sectionLabel),
                ),
                _divider(context),
                for (final (index, entry) in _entries.indexed) ...[
                  if (entry.sectionBefore && index > 0) _divider(context),
                  _row(context, index: index, entry: entry),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final theme = context.squiggleTheme;
    return Divider(
      color: theme.colors.surface1,
      height: theme.spacing.panelSectionSpacing,
      indent: theme.spacing.panelPadding,
      endIndent: theme.spacing.panelPadding,
    );
  }

  Widget _row(
    BuildContext context, {
    required int index,
    required _MenuEntry entry,
  }) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    final spacing = theme.spacing;
    final typography = theme.typography;
    final isHovering = _hoveredIndex == index;
    final foreground = entry.danger ? colors.danger : colors.text;
    final iconColor = entry.danger ? colors.danger : colors.subtext0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // UI only: no action wired up yet.
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: theme.decorations.toolbarButton(
            isActive: false,
            isHovering: isHovering,
          ),
          child: SizedBox(
            height: spacing.toolbarButtonSize,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.panelPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    entry.icon,
                    size: spacing.buttonIconSize,
                    color: iconColor,
                  ),
                  SizedBox(width: spacing.buttonIconGap),
                  Expanded(
                    child: Text(
                      entry.label,
                      overflow: TextOverflow.ellipsis,
                      style: typography.inputText.copyWith(color: foreground),
                    ),
                  ),
                  if (entry.shortcut case final shortcut?) ...[
                    SizedBox(width: spacing.panelLabelSpacing),
                    Text(shortcut, style: typography.hotkey),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

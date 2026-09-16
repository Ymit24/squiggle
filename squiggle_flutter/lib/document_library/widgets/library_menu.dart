import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LibraryMenuItem {
  const LibraryMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
    this.checked = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;
  final bool checked;
}

class LibraryMenuAnchor extends StatelessWidget {
  const LibraryMenuAnchor({
    super.key,
    required this.menuWidth,
    required this.menuItems,
    required this.buttonBuilder,
    this.onOpenChanged,
    this.alignmentOffset = const Offset(0, 8),
  });

  final double menuWidth;
  final List<LibraryMenuItem> Function() menuItems;
  final Widget Function(BuildContext context, bool open, VoidCallback toggle)
  buttonBuilder;
  final ValueChanged<bool>? onOpenChanged;
  final Offset alignmentOffset;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: alignmentOffset,
      onOpen: () => onOpenChanged?.call(true),
      onClose: () => onOpenChanged?.call(false),
      style: _menuStyle(context, menuWidth),
      menuChildren: [
        for (final item in menuItems()) _LibraryMenuButton(item: item),
      ],
      builder: (context, controller, _) => buttonBuilder(
        context,
        controller.isOpen,
        controller.isOpen ? controller.close : controller.open,
      ),
    );
  }
}

void showLibraryContextMenu({
  required BuildContext context,
  required Offset position,
  required List<LibraryMenuItem> items,
  double width = 224,
}) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final localPosition = overlay.globalToLocal(position);
  final positionRect = RelativeRect.fromSize(
    Rect.fromLTWH(localPosition.dx, localPosition.dy, 0, 0),
    overlay.size,
  );
  final colors = context.squiggleTheme.colors;

  showMenu<LibraryMenuItem>(
    context: context,
    position: positionRect,
    color: colors.mantle,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black,
    elevation: 16,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: colors.surface1),
    ),
    menuPadding: const EdgeInsets.all(6),
    constraints: BoxConstraints.tightFor(width: width),
    items: [
      for (final item in items)
        PopupMenuItem(
          value: item,
          height: 40,
          padding: EdgeInsets.zero,
          child: _LibraryMenuContent(item: item),
        ),
    ],
  ).then((item) => item?.onTap());
}

MenuStyle _menuStyle(BuildContext context, double width) {
  final colors = context.squiggleTheme.colors;
  return MenuStyle(
    alignment: AlignmentDirectional.topEnd,
    backgroundColor: WidgetStatePropertyAll(colors.mantle),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.black),
    elevation: const WidgetStatePropertyAll(16),
    padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
    fixedSize: WidgetStatePropertyAll(Size.fromWidth(width)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: colors.surface1),
      ),
    ),
  );
}

class _LibraryMenuButton extends StatelessWidget {
  const _LibraryMenuButton({required this.item});

  final LibraryMenuItem item;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: item.onTap,
      requestFocusOnHover: false,
      style: MenuItemButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _LibraryMenuContent(item: item),
    );
  }
}

class _LibraryMenuContent extends StatelessWidget {
  const _LibraryMenuContent({required this.item});

  final LibraryMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    final color = item.danger ? const Color(0xFFF28B8B) : colors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          if (item.icon case final icon?) ...[
            Icon(icon, size: 16, color: item.danger ? color : colors.subtext0),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (item.checked)
            Icon(Icons.check_rounded, size: 16, color: colors.accent),
        ],
      ),
    );
  }
}

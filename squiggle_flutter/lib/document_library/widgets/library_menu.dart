import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_button.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_content.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

export 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';

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
        for (final item in menuItems()) LibraryMenuButton(item: item),
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
    color: colors.surface0,
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
          child: LibraryMenuContent(item: item),
        ),
    ],
  ).then((item) => item?.onTap());
}

MenuStyle _menuStyle(BuildContext context, double width) {
  final colors = context.squiggleTheme.colors;
  return MenuStyle(
    alignment: AlignmentDirectional.bottomStart,
    backgroundColor: WidgetStatePropertyAll(colors.surface0),
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

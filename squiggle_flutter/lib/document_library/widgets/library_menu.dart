import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_context_menu.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

export 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';

class LibraryMenuAnchor extends StatefulWidget {
  const LibraryMenuAnchor({
    super.key,
    required this.menuItems,
    required this.buttonBuilder,
    this.onOpenChanged,
    this.alignmentOffset = const Offset(0, 8),
  });

  final List<LibraryMenuItem> Function() menuItems;
  final Widget Function(BuildContext context, bool open, VoidCallback toggle)
  buttonBuilder;
  final ValueChanged<bool>? onOpenChanged;
  final Offset alignmentOffset;

  @override
  State<LibraryMenuAnchor> createState() => _LibraryMenuAnchorState();
}

class _LibraryMenuAnchorState extends State<LibraryMenuAnchor> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      crossAxisUnconstrained: false,
      alignmentOffset: widget.alignmentOffset,
      onOpen: () => widget.onOpenChanged?.call(true),
      onClose: () => widget.onOpenChanged?.call(false),
      style: context.squiggleTheme.menuStyle(),
      menuChildren: _menuItems(widget.menuItems(), _controller.close),
      builder: (context, controller, _) => widget.buttonBuilder(
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
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final box = navigator.context.findRenderObject()! as RenderBox;
  final localPosition = box.globalToLocal(position);
  showSquiggleContextMenu(
    context: context,
    builder: (context) => SquiggleContextMenu(
      position: localPosition,
      children: _menuItems(items, () => Navigator.of(context).pop()),
    ),
  );
}

List<Widget> _menuItems(List<LibraryMenuItem> items, VoidCallback close) => [
  for (final item in items)
    SquiggleMenuItem(
      label: item.label,
      icon: item.icon,
      danger: item.danger,
      checked: item.checked,
      onPressed: () {
        close();
        item.onTap();
      },
    ),
];

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single row in a library overlay menu.
class LibraryMenuItem {
  const LibraryMenuItem({
    required this.label,
    this.icon,
    this.danger = false,
    this.checked = false,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool danger;
  final bool checked;
  final VoidCallback onTap;
}

/// Anchor-driven dropdown showing a custom overlay menu (no Material popup).
///
/// Wraps the button in the transform target plus outside-tap detection.
/// [buttonBuilder] receives the open state and a toggle callback.
class LibraryMenuAnchor extends StatefulWidget {
  const LibraryMenuAnchor({
    super.key,
    required this.menuWidth,
    required this.menuItems,
    required this.buttonBuilder,
    this.onOpenChanged,
    this.followerOffset = const Offset(0, 8),
  });

  final double menuWidth;
  final List<LibraryMenuItem> Function() menuItems;
  final Widget Function(
    BuildContext context,
    bool open,
    VoidCallback toggle,
  ) buttonBuilder;
  final ValueChanged<bool>? onOpenChanged;
  final Offset followerOffset;

  @override
  State<LibraryMenuAnchor> createState() => _LibraryMenuAnchorState();
}

class _LibraryMenuAnchorState extends State<LibraryMenuAnchor> {
  final _groupId = Object();
  OverlayEntry? _entry;

  bool get isOpen => _entry != null;

  @override
  void dispose() {
    // Close silently: no setState (element is unmounting) and no
    // onOpenChanged (the parent is going away or rebuilding anyway).
    _close(notify: false, rebuild: false);
    super.dispose();
  }

  void _toggle() {
    if (isOpen) {
      _close();
    } else {
      _open();
    }
    setState(() {});
  }

  void _open() {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Position the menu from the button's global rect with a plain
    // Positioned — no follower layer involved. Right-aligned to the
    // button, below it, or above it when space is tight.
    var left = screenSize.width - widget.menuWidth - 8;
    var top = 8.0;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final buttonTopLeft =
          renderBox.localToGlobal(Offset.zero);
      final buttonBottomRight = renderBox.localToGlobal(
        Offset(renderBox.size.width, renderBox.size.height),
      );
      left = buttonBottomRight.dx - widget.menuWidth;
      const estimatedHeight = 220.0;
      final below = buttonBottomRight.dy + widget.followerOffset.dy;
      top = below + estimatedHeight <= screenSize.height - 8
          ? below
          : buttonTopLeft.dy -
              widget.followerOffset.dy -
              estimatedHeight;
    }
    left = left.clamp(
      8.0,
      (screenSize.width - widget.menuWidth - 8).clamp(8.0, screenSize.width),
    );
    top = top.clamp(8.0, (screenSize.height - 120).clamp(8.0, screenSize.height));

    _entry = OverlayEntry(
      // NB: Overlay lays out non-positioned entry children with TIGHT
      // full-screen constraints. The Stack below re-loosens them for its
      // positioned child so the menu shrink-wraps instead of stretching
      // across the whole window.
      builder: (overlayContext) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: TapRegion(
              groupId: _groupId,
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _close();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: LibraryMenuPanel(
                  width: widget.menuWidth,
                  items: widget.menuItems(),
                  onSelected: (item) {
                    _close();
                    // Run after the overlay is gone so dialogs open cleanly.
                    Future.microtask(item.onTap);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    widget.onOpenChanged?.call(true);
  }

  void _close({bool notify = true, bool rebuild = true}) {
    if (_entry == null) return;
    _entry!.remove();
    _entry = null;
    if (notify) widget.onOpenChanged?.call(false);
    if (rebuild) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _groupId,
      onTapOutside: (_) => _close(),
      child: widget.buttonBuilder(context, isOpen, _toggle),
    );
  }
}

/// Shows a floating library menu at a global [position] (e.g. right-click).
void showLibraryContextMenu({
  required BuildContext context,
  required Offset position,
  required List<LibraryMenuItem> items,
  double width = 224,
}) {
  final overlay = Overlay.of(context);
  final screenSize = MediaQuery.of(context).size;
  late final OverlayEntry entry;
  var closed = false;
  void close() {
    if (closed) return;
    closed = true;
    entry.remove();
  }

  final estimatedHeight = items.length * 40.0 + 20;
  final left =
      position.dx.clamp(8.0, (screenSize.width - width - 8).clamp(8.0, screenSize.width));
  final top = position.dy.clamp(
      8.0, (screenSize.height - estimatedHeight - 8).clamp(8.0, screenSize.height));

  entry = OverlayEntry(
    builder: (overlayContext) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: close,
            onSecondaryTap: close,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                close();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LibraryMenuPanel(
              width: width,
              items: items,
              onSelected: (item) {
                close();
                Future.microtask(item.onTap);
              },
            ),
          ),
        ),
      ],
    ),
  );
  overlay.insert(entry);
}

/// The floating panel shared by anchored dropdowns and context menus.
///
/// Wrapped in [Material]: overlay entries live above the page's [Scaffold],
/// so without a Material ancestor text falls back to Flutter's debug
/// fallback style (monospace with a yellow double underline).
class LibraryMenuPanel extends StatelessWidget {
  const LibraryMenuPanel({
    super.key,
    required this.width,
    required this.items,
    required this.onSelected,
  });

  final double width;
  final List<LibraryMenuItem> items;
  final ValueChanged<LibraryMenuItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A48)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xB3000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _MenuRow(item: item, onTap: () => onSelected(item)),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item, required this.onTap});

  final LibraryMenuItem item;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final labelColor = item.danger
        ? const Color(0xFFF28B8B)
        : const Color(0xFFE4E4E4);
    final iconColor = item.danger
        ? const Color(0xFFF28B8B)
        : const Color(0xFFA0A0A0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _hovering
                ? const Color(0xFF2B2B37)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (item.checked)
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFFA8B3C2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

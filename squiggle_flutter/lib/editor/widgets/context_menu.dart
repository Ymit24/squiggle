import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';

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
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box =
          _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final size = box.size;
        final position = widget.localScreenPosition;
        final screenSize = MediaQuery.of(context).size;

        print("Real size $size, position $position, window size: $screenSize");

        const padding = Offset(12, 12);

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

        print("Clamped position: $clampedScreenPosition");
        setState(() {
          _localPosition = clampedScreenPosition;
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _localPosition.dx,
      top: _localPosition.dy,
      child: Opacity(
        opacity: _isVisible ? 1.0 : 0.0,
        child: Container(
          key: _key,
          child: Column(
            children: [
              Text("Cut"),
              Text("Copy"),
              Text("Paste"),
              Text("Send to front"),
              Text("Send to back"),
              Text("Send Forward"),
              Text("Send Backward"),
              Text("Group"),
              Text("Ungroup"),
              Text("Delete"),
            ],
          ),
        ),
      ),
    );
  }
}

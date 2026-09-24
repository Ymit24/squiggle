import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';

class ContextMenu extends StatelessWidget {
  final ContextMenuState state;

  const ContextMenu({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: state.localScreenPosition.dx,
      top: state.localScreenPosition.dy,
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
    );
  }
}

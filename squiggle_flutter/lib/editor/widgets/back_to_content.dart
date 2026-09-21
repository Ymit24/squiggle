import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';

class BackToContent extends StatelessWidget {
  const BackToContent({super.key, required this.editorContext});

  final EditorContext editorContext;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editorContext,
      builder: (context, _) {
        final nodesOnScreen = editorContext.camera.getNodesInViewport(
          editorContext.document,
        );
        if (nodesOnScreen.isNotEmpty) {
          return SizedBox.shrink();
        }
        return TextButton(
          onPressed: () {
            print("CLICK");
          },
          child: Text("go back."),
        );
      },
    );
  }
}

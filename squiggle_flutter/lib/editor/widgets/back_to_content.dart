import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

void jumpBackToContent(EditorContext context) {
  final nodes = context.document.nodes;
  if (nodes.isEmpty || context.viewportSize == Size.zero) return;

  final cameraOrigin = context.camera.location;
  var closest = nodes.first;
  var closestDistance = (closest.origin - cameraOrigin).distanceSquared;
  for (final node in nodes.skip(1)) {
    final distance = (node.origin - cameraOrigin).distanceSquared;
    if (distance < closestDistance) {
      closest = node;
      closestDistance = distance;
    }
  }

  context.cancelViewportMotion();
  context.camera.location = closest.center();
  context.camera.panByScreenDelta(context.viewportSize.center(Offset.zero));
  context.notifyViewportChanged();
}

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
          editorContext.viewportSize,
        );

        if (nodesOnScreen.isNotEmpty || editorContext.document.nodes.isEmpty) {
          return SizedBox.shrink();
        }

        return SquiggleButton(
          label: 'Back to content',
          leading: const Icon(Icons.center_focus_strong_rounded),
          onPressed: () => jumpBackToContent(editorContext),
        );
      },
    );
  }
}

part of '../select_tool_3.dart';

class IdleInteractionState extends InteractionState {
  IdleInteractionState({required super.parent});

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return switch (getTargetUnderCursor(context, worldPosition)) {
      ResizeHandleTarget(handle: final handle) => cursorForResizeHandle(
        handle.handle,
      ),
      PolylineHandleTarget() => EditorCursor.grab,
      NodeTarget() => EditorCursor.grab,
      CanvasTarget() => EditorCursor.basic,
      _ => EditorCursor.basic,
    };
  }

  @override
  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: idle state down. Hit target: $target");
    switch (target) {
      case ResizeHandleTarget(handle: var handle):
        print("D: Clicked on handle: ${target.handle}");
        parent.transition(
          ResizeState(
            parent: parent,
            handle: handle,
            pointerDownWorld: cursorWorldPosition,
          ),
          context,
        );
        break;
      case PolylineHandleTarget(handle: var handle):
        print("D: Clicked on polyline handle: ${target.handle}");
        parent.transition(
          DragPolylineHandleState(parent: parent, handle: handle),
          context,
        );
        break;
      case NodeTarget(node: var chaseNode):
        final selectedNodes = context.selection.selectedFeatures.map(
          (id) => context.document.featureById(id),
        );
        if (selectedNodes.any((f) => f == null)) {
          // TODO: Is this possible? What to do?
          return;
        }
        parent.transition(
          ClickNodeState(
            parent: parent,
            start: cursorWorldPosition,
            chase: chaseNode,
            selectedNodes: selectedNodes.map((f) => f!).toList(),
            isShiftPressed: isShiftPressed,
          ),
          context,
        );
        break;
      case CanvasTarget():
        parent.transition(
          ClickCanvasState(parent: parent, start: cursorWorldPosition),
          context,
        );
        break;
    }
  }

  @override
  void onDoubleClick(
    EditorContext context,
    HitTarget target,
    Offset worldPosition,
    Camera camera,
  ) {
    print("D: Idle double click on target: $target!");
    if (target case NodeTarget(
      node: final Feature feature,
    ) when feature.kind is FeatureKindText) {
      final text = feature.kind as FeatureKindText;
      context.selection.setSelection([feature.id]);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: text.contents,
          canvasLocalBounds: camera.worldToScreenBounds(feature.bounds()),
        ),
      );
      return;
    }
  }
}

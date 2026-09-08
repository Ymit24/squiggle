part of '../select_tool_3.dart';

class DragPolylineHandleState extends InteractionState {
  DragPolylineHandleState({required super.parent, required this._handle});

  final PolylineHandle _handle;
  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.grabbing;
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final kind = _handle.feature.kind as FeatureKindPolyline;
    final target = _targetPosition(
      kind,
      cursorWorldPosition,
      isShiftPressed: isShiftPressed,
    );
    kind.setPoint(_handle.feature, _handle.pointIndex, target);
  }

  Offset _targetPosition(
    FeatureKindPolyline kind,
    Offset cursorWorldPosition, {
    required bool isShiftPressed,
  }) {
    if (!isShiftPressed) return cursorWorldPosition;

    final points = worldPoints(_handle.feature.origin, kind.localPoints);
    final origin = _snapOrigin(points, cursorWorldPosition);
    return snapPointTo45DegreeAngle(origin, cursorWorldPosition);
  }

  Offset _snapOrigin(List<Offset> points, Offset fallback) {
    if (_handle.pointIndex > 0) return points[_handle.pointIndex - 1];
    if (points.length > 1) return points[1];
    return fallback;
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

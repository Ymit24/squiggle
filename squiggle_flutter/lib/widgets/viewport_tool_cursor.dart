import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

MouseCursor _mouseCursorFor(EditorCursor cursor) {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return switch (cursor) {
      EditorCursor.resizeUpLeft => SystemMouseCursors.resizeLeft,
      EditorCursor.resizeUpRight => SystemMouseCursors.resizeRight,
      EditorCursor.resizeDownLeft => SystemMouseCursors.resizeLeft,
      EditorCursor.resizeDownRight => SystemMouseCursors.resizeRight,
      _ => _defaultMouseCursorFor(cursor),
    };
  }

  return switch (cursor) {
    EditorCursor.resizeUpLeft ||
    EditorCursor.resizeDownRight => SystemMouseCursors.resizeUpLeftDownRight,
    EditorCursor.resizeUpRight ||
    EditorCursor.resizeDownLeft => SystemMouseCursors.resizeUpRightDownLeft,
    _ => _defaultMouseCursorFor(cursor),
  };
}

MouseCursor _defaultMouseCursorFor(EditorCursor cursor) {
  return switch (cursor) {
    EditorCursor.basic => SystemMouseCursors.basic,
    EditorCursor.grab => SystemMouseCursors.grab,
    EditorCursor.grabbing => SystemMouseCursors.grabbing,
    EditorCursor.resizeUpLeft => SystemMouseCursors.resizeUpLeft,
    EditorCursor.resizeUp => SystemMouseCursors.resizeUp,
    EditorCursor.resizeUpRight => SystemMouseCursors.resizeUpRight,
    EditorCursor.resizeRight => SystemMouseCursors.resizeRight,
    EditorCursor.resizeDownRight => SystemMouseCursors.resizeDownRight,
    EditorCursor.resizeDown => SystemMouseCursors.resizeDown,
    EditorCursor.resizeDownLeft => SystemMouseCursors.resizeDownLeft,
    EditorCursor.resizeLeft => SystemMouseCursors.resizeLeft,
    EditorCursor.crosshair => SystemMouseCursors.precise,
  };
}

/// Applies the active tool's hover cursor over the document canvas.
class ViewportToolCursor extends StatefulWidget {
  const ViewportToolCursor({
    super.key,
    required this.documentRepository,
    required this.selectionRepository,
    required this.toolRepository,
    required this.camera,
    required this.canvasKey,
    required this.child,
  });

  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;
  final ToolRepository toolRepository;
  final Camera camera;
  final GlobalKey canvasKey;
  final Widget child;

  @override
  State<ViewportToolCursor> createState() => _ViewportToolCursorState();
}

class _ViewportToolCursorState extends State<ViewportToolCursor> {
  MouseCursor _cursor = SystemMouseCursors.basic;
  Offset? _lastPointerGlobal;
  bool _pointerDown = false;
  StreamSubscription<void>? _repaintSubscription;

  @override
  void initState() {
    super.initState();
    _repaintSubscription = widget.toolRepository.repaintStream.listen((_) {
      _resolveAtLastPointer();
    });
  }

  @override
  void dispose() {
    _repaintSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ViewportToolCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera.zoom != widget.camera.zoom ||
        oldWidget.camera.location != widget.camera.location) {
      _resolveAtLastPointer();
    }
  }

  Offset? _worldFromGlobal(Offset global) {
    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return widget.camera.screenToWorld(renderBox.globalToLocal(global));
  }

  void _resolveAtLastPointer() {
    final global = _lastPointerGlobal;
    if (global == null) return;
    _updateCursor(global);
  }

  void _updateCursor(Offset global) {
    final world = _worldFromGlobal(global);
    if (world == null) return;
    final next = _mouseCursorFor(
      widget.toolRepository.resolveCursor(
        widget.documentRepository,
        world,
        widget.selectionRepository,
        widget.camera,
      ),
    );
    if (next == _cursor) return;
    setState(() => _cursor = next);
  }

  void _trackPointer(PointerEvent event) {
    _lastPointerGlobal = event.position;
    _updateCursor(event.position);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointerDown = true;
        _trackPointer(event);
      },
      onPointerMove: _trackPointer,
      onPointerUp: (event) {
        _pointerDown = false;
        _trackPointer(event);
      },
      onPointerCancel: (event) {
        _pointerDown = false;
        _trackPointer(event);
      },
      child: MouseRegion(
        cursor: _cursor,
        onHover: _trackPointer,
        onExit: (_) {
          if (_pointerDown) return;
          _lastPointerGlobal = null;
          if (_cursor == SystemMouseCursors.basic) return;
          setState(() => _cursor = SystemMouseCursors.basic);
        },
        child: widget.child,
      ),
    );
  }
}

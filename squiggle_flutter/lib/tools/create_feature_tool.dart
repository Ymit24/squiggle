import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class CreateFeatureTool extends Tool {
  CreateFeatureTool({required this._ghost}) : _state = const _Idle();

  factory CreateFeatureTool.rect() => CreateFeatureTool(
    ghost: Feature(
      origin: Offset.zero,
      size: const Size(1, 1),
      kind: const FeatureKindRectangle(),
    ),
  );

  factory CreateFeatureTool.circle() => CreateFeatureTool(
    ghost: Feature(
      origin: Offset.zero,
      size: const Size(1, 1),
      kind: const FeatureKindCircle(),
    ),
  );

  Feature _ghost;
  _CreateState _state;

  @override
  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) =>
      EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    DocumentRepository documentRepository,
    SelectionRepository selection,
  ) {
    if (_state is! _Dragging) return;
    _ghost.paint(canvas);
  }

  @override
  void deactivate(SelectionRepository selection) {}

  @override
  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {}

  @override
  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    switch (_state) {
      case _Idle():
        _state = _Dragging(start: worldPosition);
        _ghost.setBounds(Rect.fromLTWH(
          worldPosition.dx,
          worldPosition.dy,
          1,
          1,
        ));
      case _Dragging(:final start):
        _ghost.setBounds(Rect.fromPoints(start, worldPosition));
    }
  }

  @override
  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    if (_state is _Dragging) {
      documentRepository.executeCommand(
        AddFeatureCommand(_ghost.copyWith(id: noId)),
      );
      _state = const _Idle();
    }
  }
}

sealed class _CreateState {
  const _CreateState();
}

final class _Idle extends _CreateState {
  const _Idle();
}

final class _Dragging extends _CreateState {
  const _Dragging({required this.start});

  final Offset start;
}

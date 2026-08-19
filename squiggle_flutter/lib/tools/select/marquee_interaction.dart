import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';

import 'select_interaction.dart';

/// Rubber-band selection rectangle that selects intersecting features.
class MarqueeInteraction extends SelectInteraction {
  MarqueeInteraction({required this.start, required this.end});

  final Offset start;
  Offset end;

  @override
  void update(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    end = worldPosition;
    _updateMarqueeSelection(context.document, context.selection, isShiftPressed);
  }

  @override
  void commit(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void _updateMarqueeSelection(
    Document document,
    SelectionModel selection,
    bool isShiftPressed,
  ) {
    final bounds = Rect.fromPoints(start, end);
    final hits = document.features
        .where((f) => f.intersectsRect(bounds))
        .map((f) => f.id)
        .toList();

    if (isShiftPressed) {
      for (final id in hits) {
        selection.selectFeature(id);
      }
    } else {
      selection.setSelection(hits);
    }
  }
}
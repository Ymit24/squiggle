import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import '../models/camera.dart';
import '../models/document.dart';
import '../models/feature.dart';

/// Paints a [Document]'s features on an infinite world-space grid.
class DocumentCanvas extends LeafRenderObjectWidget {
  const DocumentCanvas({
    super.key,
    required this.document,
    required this.camera,
    required this.selectedFeatures,
  });

  final Document document;
  final Camera camera;
  final List<FeatureId> selectedFeatures;
  @override
  RenderDocumentCanvas createRenderObject(BuildContext context) {
    return RenderDocumentCanvas(
      document: document,
      camera: camera,
      selectedFeatures: selectedFeatures,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDocumentCanvas renderObject,
  ) {
    renderObject
      ..document = document
      ..camera = camera
      ..selectedFeatures = selectedFeatures;
  }
}

class RenderDocumentCanvas extends RenderBox {
  RenderDocumentCanvas({
    required this._document,
    required this._camera,
    required this._selectedFeatures,
  });

  Document _document;
  Document get document => _document;
  set document(Document value) {
    if (identical(_document, value)) return;
    _document = value;
    markNeedsPaint();
  }

  Camera _camera;
  Camera get camera => _camera;
  set camera(Camera value) {
    _camera = value;
    markNeedsPaint();
  }

  List<FeatureId> _selectedFeatures;
  List<FeatureId> get selectedFeatures => _selectedFeatures;
  set selectedFeatures(List<FeatureId> value) {
    if (identical(_selectedFeatures, value)) return;
    _selectedFeatures = value;
    markNeedsPaint();
  }

  static const double _baseCellSize = 128.0;

  @override
  void performLayout() {
    size = constraints.biggest.isFinite
        ? constraints.constrain(constraints.biggest)
        : constraints.constrain(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final clip = offset & size;

    _camera.setViewportOrigin(offset);

    canvas.save();
    canvas.clipRect(clip);

    canvas.save();
    _applyWorldTransform(canvas);
    _drawGrid(canvas);
    _paintFeatures(canvas);
    canvas.restore();

    canvas.restore();
  }

  void _applyWorldTransform(Canvas canvas) {
    final zoom = _camera.zoom;
    if (zoom <= 0) return;

    final location = _camera.location;
    final origin = _camera.viewportOrigin;
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(1 / zoom, 1 / zoom);
    canvas.translate(-location.dx, -location.dy);
  }

  void _drawGrid(Canvas canvas) {
    final zoom = _camera.zoom;
    if (zoom <= 0) return;

    final location = _camera.location;
    final firstGridX = (location.dx / _baseCellSize).floor() * _baseCellSize;
    final firstGridY = (location.dy / _baseCellSize).floor() * _baseCellSize;

    final visibleWorld = Rect.fromLTWH(
      location.dx,
      location.dy,
      size.width * zoom,
      size.height * zoom,
    );

    final paint = Paint()
      ..color = const Color(0xFF45475A)
      ..style = PaintingStyle.fill;

    final lineWidth = zoom;

    for (
      var x = firstGridX;
      x < visibleWorld.right + _baseCellSize;
      x += _baseCellSize
    ) {
      canvas.drawRect(
        Rect.fromLTWH(x, visibleWorld.top, lineWidth, visibleWorld.height),
        paint,
      );
    }
    for (
      var y = firstGridY;
      y < visibleWorld.bottom + _baseCellSize;
      y += _baseCellSize
    ) {
      canvas.drawRect(
        Rect.fromLTWH(visibleWorld.left, y, visibleWorld.width, lineWidth),
        paint,
      );
    }
  }

  void _paintFeatures(Canvas canvas) {
    final zoom = _camera.zoom;
    if (zoom <= 0) return;

    final visibleWorld = Rect.fromLTWH(
      _camera.location.dx,
      _camera.location.dy,
      size.width * zoom,
      size.height * zoom,
    );

    for (final feature in _document.features) {
      final worldBounds = feature.bounds();
      if (!worldBounds.overlaps(visibleWorld)) continue;

      print("Selected Features: $selectedFeatures");
      print("Feature ID: ${feature.id}");
      if (selectedFeatures.contains(feature.id)) {
        print("Did have feature! ${feature.id}");
        canvas.drawRect(
          worldBounds.inflate(8),

          Paint()
            ..color = const Color(0xFF89B4FA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      _paintFeature(canvas, feature, worldBounds);
    }
  }

  void _paintFeature(Canvas canvas, Feature feature, Rect worldBounds) {
    switch (feature.kind) {
      case FeatureKindRectangle():
        canvas.drawRect(worldBounds, Paint()..color = const Color(0xFFCDA6F7));
      case FeatureKindCircle():
        canvas.drawOval(worldBounds, Paint()..color = const Color(0xFFF38BA8));
      case FeatureKindText(:final contents):
        _paintText(canvas, contents, worldBounds);
    }
  }

  void _paintText(Canvas canvas, String contents, Rect worldBounds) {
    if (contents.isEmpty) return;

    final fontSize = worldBounds.height;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        textDirection: TextDirection.ltr,
      ),
    )..pushStyle(ui.TextStyle(color: const Color(0xFFCDD6F4)));
    builder.addText(contents);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: worldBounds.width));

    canvas.drawParagraph(paragraph, worldBounds.topLeft);
  }
}

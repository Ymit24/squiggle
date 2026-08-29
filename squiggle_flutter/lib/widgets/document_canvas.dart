import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import '../models/document.dart';

/// Paints a [Document]'s features on an infinite world-space grid.
class DocumentCanvas extends LeafRenderObjectWidget {
  const DocumentCanvas({
    super.key,
    required this.context,
    required this.imageRepository,
  });

  final EditorContext context;
  final ImageRepository imageRepository;

  @override
  RenderDocumentCanvas createRenderObject(BuildContext context) {
    return RenderDocumentCanvas(
      context: this.context,
      imageRepository: imageRepository,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDocumentCanvas renderObject,
  ) {
    renderObject
      ..context = this.context
      ..imageRepository = imageRepository
      ..markNeedsPaint();
  }
}

class RenderDocumentCanvas extends RenderBox {
  RenderDocumentCanvas({
    required this._context,
    required this._imageRepository,
  });

  EditorContext _context;
  EditorContext get context => _context;
  set context(EditorContext value) {
    if (identical(_context, value)) return;
    _unsubscribeFromContext();
    _context = value;
    _subscribeToContext();
    markNeedsPaint();
  }

  ImageRepository _imageRepository;
  ImageRepository get imageRepository => _imageRepository;
  set imageRepository(ImageRepository value) {
    if (identical(_imageRepository, value)) return;
    _unsubscribeFromImageRepaints();
    _imageRepository = value;
    _subscribeToImageRepaints();
    markNeedsPaint();
  }

  StreamSubscription<void>? _imageRepaintSubscription;

  // The grid is based on powers of two so it changes scale without visibly
  // drifting away from the document origin. The target sizes are in screen
  // pixels; the actual spacing is chosen in world space below.
  static const double _gridUnit = 128.0;
  static const double _minMajorScreenSize = 64.0;
  static const double _maxMajorScreenSize = 160.0;
  static const Color _canvasColor = Color(0xFF171717);
  static const Color _minorGridColor = Color(0xFF252525);
  static const Color _majorGridColor = Color(0xFF363636);

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _subscribeToContext();
    _subscribeToImageRepaints();
  }

  @override
  void detach() {
    _unsubscribeFromContext();
    _unsubscribeFromImageRepaints();
    super.detach();
  }

  void _subscribeToContext() {
    _context.addListener(markNeedsPaint);
  }

  void _unsubscribeFromContext() {
    _context.removeListener(markNeedsPaint);
  }

  void _subscribeToImageRepaints() {
    _imageRepaintSubscription ??= _imageRepository.repaintStream.listen(
      (_) => markNeedsPaint(),
    );
  }

  void _unsubscribeFromImageRepaints() {
    _imageRepaintSubscription?.cancel();
    _imageRepaintSubscription = null;
  }

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
    final document = _context.document;
    final camera = _context.camera;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(Offset.zero & size);
    _drawBackground(canvas);

    canvas.save();
    _applyWorldTransform(canvas);
    _drawGrid(canvas);
    _paintFeatures(canvas, document);
    _context.tool.activeTool.paint(canvas, camera, _context, _imageRepository);
    canvas.restore();

    canvas.restore();
  }

  void _applyWorldTransform(Canvas canvas) {
    final zoom = _context.camera.zoom;
    if (zoom <= 0) return;

    final location = _context.camera.location;
    canvas.scale(1 / zoom, 1 / zoom);
    canvas.translate(-location.dx, -location.dy);
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _canvasColor);
  }

  void _drawGrid(Canvas canvas) {
    final zoom = _context.camera.zoom;
    if (zoom <= 0) return;

    final location = _context.camera.location;
    var majorCellSize = _gridUnit;
    var majorScreenSize = majorCellSize / zoom;

    while (majorScreenSize < _minMajorScreenSize) {
      majorCellSize *= 2;
      majorScreenSize *= 2;
    }
    while (majorScreenSize > _maxMajorScreenSize) {
      majorCellSize /= 2;
      majorScreenSize /= 2;
    }

    final minorCellSize = majorCellSize / 4;
    final firstMinorGridX =
        (location.dx / minorCellSize).floor() * minorCellSize;
    final firstMinorGridY =
        (location.dy / minorCellSize).floor() * minorCellSize;

    final visibleWorld = Rect.fromLTWH(
      location.dx,
      location.dy,
      size.width * zoom,
      size.height * zoom,
    );

    final minorPaint = Paint()
      ..color = _minorGridColor
      ..style = PaintingStyle.fill;
    final majorPaint = Paint()
      ..color = _majorGridColor
      ..style = PaintingStyle.fill;

    final minorLineWidth = zoom * 0.6;
    final majorLineWidth = zoom * 1.2;

    for (
      var x = firstMinorGridX;
      x < visibleWorld.right + minorCellSize;
      x += minorCellSize
    ) {
      final isMajor =
          ((x / majorCellSize).round() * majorCellSize - x).abs() <
          minorCellSize / 100;
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          visibleWorld.top,
          isMajor ? majorLineWidth : minorLineWidth,
          visibleWorld.height,
        ),
        isMajor ? majorPaint : minorPaint,
      );
    }
    for (
      var y = firstMinorGridY;
      y < visibleWorld.bottom + minorCellSize;
      y += minorCellSize
    ) {
      final isMajor =
          ((y / majorCellSize).round() * majorCellSize - y).abs() <
          minorCellSize / 100;
      canvas.drawRect(
        Rect.fromLTWH(
          visibleWorld.left,
          y,
          visibleWorld.width,
          isMajor ? majorLineWidth : minorLineWidth,
        ),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  void _paintFeatures(Canvas canvas, Document document) {
    final zoom = _context.camera.zoom;
    if (zoom <= 0) return;

    final visibleWorld = Rect.fromLTWH(
      _context.camera.location.dx,
      _context.camera.location.dy,
      size.width * zoom,
      size.height * zoom,
    );

    for (final feature in document.features) {
      final worldBounds = feature.bounds();
      if (!worldBounds.overlaps(visibleWorld)) continue;

      feature.paint(canvas, _imageRepository);
    }
  }
}

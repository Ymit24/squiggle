import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import '../models/document.dart';
import '../utils/grid.dart';

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

  static const Color _canvasColor = Color(0xFF171717);

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
    paintAdaptiveGrid(
      canvas,
      size: size,
      location: _context.camera.location,
      zoom: _context.camera.zoom,
    );
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

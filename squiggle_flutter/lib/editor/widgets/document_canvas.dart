import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/utils/grid.dart';

/// Paints a [Document]'s nodes on an infinite world-space grid.
class DocumentCanvas extends LeafRenderObjectWidget {
  const DocumentCanvas({
    super.key,
    required this.context,
    required this.imageRepository,
    required this.colors,
  });

  final EditorContext context;
  final ImageRepository imageRepository;

  /// Canvas background (`base`) and grid lines (`surface0`, `surface1`).
  final SquiggleColorScheme colors;

  @override
  RenderDocumentCanvas createRenderObject(BuildContext context) {
    return RenderDocumentCanvas(
      context: this.context,
      imageRepository: imageRepository,
      colors: colors,
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
      ..colors = colors
      ..markNeedsPaint();
  }
}

class RenderDocumentCanvas extends RenderBox {
  RenderDocumentCanvas({
    required this._context,
    required this._imageRepository,
    required this._colors,
  });

  EditorContext _context;

  ImageRepository _imageRepository;

  StreamSubscription<void>? _imageRepaintSubscription;

  SquiggleColorScheme _colors;
  EditorContext get context => _context;
  set context(EditorContext value) {
    if (identical(_context, value)) return;
    _unsubscribeFromContext();
    _context = value;
    _subscribeToContext();
    markNeedsPaint();
  }

  ImageRepository get imageRepository => _imageRepository;
  set imageRepository(ImageRepository value) {
    if (identical(_imageRepository, value)) return;
    _unsubscribeFromImageRepaints();
    _imageRepository = value;
    _subscribeToImageRepaints();
    markNeedsPaint();
  }

  SquiggleColorScheme get colors => _colors;
  set colors(SquiggleColorScheme value) {
    if (identical(_colors, value)) return;
    _colors = value;
    markNeedsPaint();
  }

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
      minorColor: _colors.surface0,
      majorColor: _colors.surface1,
    );
    _paintNodes(canvas, document);
    _context.tool.activeTool.paint(canvas, camera, _context, _imageRepository);
    canvas.restore();

    canvas.restore();
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

  void _applyWorldTransform(Canvas canvas) {
    final zoom = _context.camera.zoom;
    if (zoom <= 0) return;

    final location = _context.camera.location;
    canvas.scale(1 / zoom, 1 / zoom);
    canvas.translate(-location.dx, -location.dy);
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _colors.base);
  }

  void _paintNodes(Canvas canvas, Document document) {
    final zoom = _context.camera.zoom;
    if (zoom <= 0) return;

    final visibleWorld = Rect.fromLTWH(
      _context.camera.location.dx,
      _context.camera.location.dy,
      size.width * zoom,
      size.height * zoom,
    );

    for (final node in document.nodes) {
      final worldBounds = node.localBounds();
      if (!worldBounds.overlaps(visibleWorld)) continue;

      node.paint(canvas, _imageRepository);
    }
  }
}

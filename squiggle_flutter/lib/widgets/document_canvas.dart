import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import '../models/camera.dart';
import '../models/document.dart';

/// Paints a [Document]'s features on an infinite world-space grid.
class DocumentCanvas extends LeafRenderObjectWidget {
  const DocumentCanvas({
    super.key,
    required this.documentRepository,
    required this.toolRepository,
    required this.selectionRepository,
    required this.imageRepository,
    required this.camera,
  });

  final DocumentRepository documentRepository;
  final ToolRepository toolRepository;
  final SelectionRepository selectionRepository;
  final ImageRepository imageRepository;
  final Camera camera;

  @override
  RenderDocumentCanvas createRenderObject(BuildContext context) {
    return RenderDocumentCanvas(
      documentRepository: documentRepository,
      toolRepository: toolRepository,
      selectionRepository: selectionRepository,
      imageRepository: imageRepository,
      camera: camera,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDocumentCanvas renderObject,
  ) {
    renderObject
      ..documentRepository = documentRepository
      ..toolRepository = toolRepository
      ..selectionRepository = selectionRepository
      ..imageRepository = imageRepository
      ..camera = camera
      ..markNeedsPaint();
  }
}

class RenderDocumentCanvas extends RenderBox {
  RenderDocumentCanvas({
    required this._documentRepository,
    required this._toolRepository,
    required this._selectionRepository,
    required this._imageRepository,
    required this._camera,
  });

  DocumentRepository _documentRepository;
  DocumentRepository get documentRepository => _documentRepository;
  set documentRepository(DocumentRepository value) {
    if (identical(_documentRepository, value)) return;
    _unsubscribeFromDocumentChanges();
    _documentRepository = value;
    _subscribeToDocumentChanges();
    markNeedsPaint();
  }

  ToolRepository _toolRepository;
  ToolRepository get toolRepository => _toolRepository;
  set toolRepository(ToolRepository value) {
    if (identical(_toolRepository, value)) return;
    _unsubscribeFromToolRepaints();
    _toolRepository = value;
    _subscribeToToolRepaints();
    markNeedsPaint();
  }

  SelectionRepository _selectionRepository;
  SelectionRepository get selectionRepository => _selectionRepository;
  set selectionRepository(SelectionRepository value) {
    if (identical(_selectionRepository, value)) return;
    _unsubscribeFromSelectionChanges();
    _selectionRepository = value;
    _subscribeToSelectionChanges();
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

  Camera _camera;
  Camera get camera => _camera;
  set camera(Camera value) {
    _camera = value;
    markNeedsPaint();
  }

  StreamSubscription<void>? _documentChangesSubscription;
  StreamSubscription<void>? _toolRepaintSubscription;
  StreamSubscription<List<dynamic>>? _selectionChangesSubscription;
  StreamSubscription<void>? _imageRepaintSubscription;

  static const double _baseCellSize = 128.0;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _subscribeToDocumentChanges();
    _subscribeToToolRepaints();
    _subscribeToSelectionChanges();
    _subscribeToImageRepaints();
  }

  @override
  void detach() {
    _unsubscribeFromDocumentChanges();
    _unsubscribeFromToolRepaints();
    _unsubscribeFromSelectionChanges();
    _unsubscribeFromImageRepaints();
    super.detach();
  }

  void _subscribeToDocumentChanges() {
    _documentChangesSubscription ??= _documentRepository.changesStream.listen(
      (_) => markNeedsPaint(),
    );
  }

  void _unsubscribeFromDocumentChanges() {
    _documentChangesSubscription?.cancel();
    _documentChangesSubscription = null;
  }

  void _subscribeToToolRepaints() {
    _toolRepaintSubscription ??= _toolRepository.repaintStream.listen(
      (_) => markNeedsPaint(),
    );
  }

  void _unsubscribeFromToolRepaints() {
    _toolRepaintSubscription?.cancel();
    _toolRepaintSubscription = null;
  }

  void _subscribeToSelectionChanges() {
    _selectionChangesSubscription ??=
        _selectionRepository.selectedFeaturesStream.listen(
      (_) => markNeedsPaint(),
    );
  }

  void _unsubscribeFromSelectionChanges() {
    _selectionChangesSubscription?.cancel();
    _selectionChangesSubscription = null;
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
    final document = _documentRepository.document;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(Offset.zero & size);

    canvas.save();
    _applyWorldTransform(canvas);
    _drawGrid(canvas);
    _paintFeatures(canvas, document);
    _toolRepository.activeTool.paint(
      canvas,
      _camera,
      _documentRepository,
      _selectionRepository,
      _imageRepository,
    );
    canvas.restore();

    canvas.restore();
  }

  void _applyWorldTransform(Canvas canvas) {
    final zoom = _camera.zoom;
    if (zoom <= 0) return;

    final location = _camera.location;
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

  void _paintFeatures(Canvas canvas, Document document) {
    final zoom = _camera.zoom;
    if (zoom <= 0) return;

    final visibleWorld = Rect.fromLTWH(
      _camera.location.dx,
      _camera.location.dy,
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

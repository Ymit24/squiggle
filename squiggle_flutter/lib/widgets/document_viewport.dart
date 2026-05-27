import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import '../models/camera.dart';
import '../theme/squiggle_colors.dart';
import 'document_canvas.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({
    super.key,
    required this.documentRepository,
    required this.selectionRepository,
    required this.toolRepository,
    this.camera,
    required this.selectedFeatures,
  });

  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;
  final ToolRepository toolRepository;
  final Camera? camera;
  final List<FeatureId> selectedFeatures;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

  late Camera _camera;
  double _initialZoom = 1.0;
  Offset _initialLocation = Offset.zero;
  Offset? _pointerInCanvas;
  bool _isPrimaryDragging = false;

  @override
  void initState() {
    super.initState();
    _camera = widget.camera ?? Camera();
  }

  @override
  void didUpdateWidget(DocumentViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.camera != null && widget.camera != oldWidget.camera) {
      _camera = widget.camera!;
    }
  }

  Offset? _canvasLocal(PointerEvent event) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return null;
    }
    return renderBox.globalToLocal(event.position);
  }

  Offset? _screenToWorld(PointerEvent event) {
    final local = _canvasLocal(event);
    if (local == null) return null;
    return _camera.screenToWorld(local);
  }

  bool get _isShiftPressed => HardwareKeyboard.instance.isShiftPressed;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        EditorShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
        if (event.buttons != kPrimaryButton) return;
        final world = _screenToWorld(event);
        if (world == null) return;
        _isPrimaryDragging = true;
        _pointerInCanvas = _canvasLocal(event);
        widget.toolRepository.onPointerDown(
          widget.documentRepository,
          world,
          widget.selectionRepository,
          _isShiftPressed,
        );
        setState(() {});
      },
      onPointerMove: (event) {
        _pointerInCanvas = _canvasLocal(event);
        if (!_isPrimaryDragging) return;
        final world = _screenToWorld(event);
        if (world == null) return;
        widget.toolRepository.onPointerMove(
          widget.documentRepository,
          world,
          widget.selectionRepository,
          _isShiftPressed,
        );
        setState(() {});
      },
      onPointerUp: (event) {
        if (!_isPrimaryDragging) return;
        _isPrimaryDragging = false;
        final world = _screenToWorld(event);
        if (world != null) {
          widget.toolRepository.onPointerUp(
            widget.documentRepository,
            world,
            widget.selectionRepository,
            _isShiftPressed,
          );
        }
        setState(() {});
      },
      onPointerCancel: (event) {
        if (!_isPrimaryDragging) return;
        _isPrimaryDragging = false;
        final world = _screenToWorld(event);
        if (world != null) {
          widget.toolRepository.onPointerUp(
            widget.documentRepository,
            world,
            widget.selectionRepository,
            _isShiftPressed,
          );
        }
        setState(() {});
      },
      onPointerPanZoomStart: (event) {
        _initialZoom = _camera.zoom;
        _initialLocation = _camera.location;
        _pointerInCanvas = _canvasLocal(event);
      },
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        final focal = _canvasLocal(event);
        if (focal == null) return;
        setState(() {
          final factor = math.exp(-event.scrollDelta.dy * 0.002);
          _camera.zoomToward(focal, 1 / factor);
        });
      },
      onPointerPanZoomUpdate: (event) {
        setState(() {
          final focal = _pointerInCanvas ?? _canvasLocal(event);
          if (focal == null) return;
          final prevZoom = _initialZoom;
          final newZoom = (_initialZoom / math.pow(event.scale, 1.75)).clamp(
            0.05,
            10.0,
          );
          _camera.zoom = newZoom;
          _camera.location =
              _initialLocation +
              focal * (prevZoom - newZoom) -
              event.pan * newZoom;
        });
      },
      child: Container(
        key: _viewportKey,
        color: SquiggleColors.base,
        child: DocumentCanvas(
          key: _canvasKey,
          documentRepository: widget.documentRepository,
          toolRepository: widget.toolRepository,
          camera: _camera,
          selectedFeatures: widget.selectedFeatures,
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../models/camera.dart';
import '../models/document.dart';
import 'document_canvas.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({super.key, required this.document, this.camera});

  final Document document;
  final Camera? camera;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport> {
  final GlobalKey _viewportKey = GlobalKey();

  late Camera _camera;
  double _initialZoom = 1.0;
  Offset _initialLocation = Offset.zero;
  Offset? _pointerInViewport;

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

  Offset _viewportLocal(PointerEvent event) {
    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return event.localPosition;
    }
    return renderBox.globalToLocal(event.position);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) {
        _pointerInViewport = _viewportLocal(event);
      },
      onPointerMove: (event) {
        _pointerInViewport = _viewportLocal(event);
      },
      onPointerPanZoomStart: (event) {
        _initialZoom = _camera.zoom;
        _initialLocation = _camera.location;
        _pointerInViewport = _viewportLocal(event);
      },
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        setState(() {
          final factor = math.exp(-event.scrollDelta.dy * 0.002);
          final focal = _viewportLocal(event);
          _camera.zoomToward(focal, 1 / factor);
        });
      },
      onPointerPanZoomUpdate: (event) {
        setState(() {
          final focal = _pointerInViewport ?? _viewportLocal(event);
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
        color: const Color(0xFF1E1E2E),
        child: DocumentCanvas(document: widget.document, camera: _camera),
      ),
    );
  }
}

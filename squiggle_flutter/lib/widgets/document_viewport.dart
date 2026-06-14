import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import '../models/camera.dart';
import '../theme/squiggle_colors.dart';
import 'document_canvas.dart';
import 'viewport_tool_cursor.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({
    super.key,
    required this.documentRepository,
    required this.selectionRepository,
    required this.toolRepository,
    required this.selectedFeatures,
  });

  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;
  final ToolRepository toolRepository;
  final List<FeatureId> selectedFeatures;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport>
    with SingleTickerProviderStateMixin {
  static const _flingFriction = 0.135;
  static const _pinchScaleThreshold = 0.02;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

  late Camera _camera;
  double _initialZoom = 1.0;
  Offset _initialLocation = Offset.zero;
  Offset? _pointerInCanvas;
  bool _isPrimaryDragging = false;
  bool _panZoomHadSignificantPinch = false;

  VelocityTracker _panVelocityTracker =
      VelocityTracker.withKind(PointerDeviceKind.trackpad);
  late final Ticker _flingTicker;
  FrictionSimulation? _flingSimX;
  FrictionSimulation? _flingSimY;
  double _flingSimXPos = 0;
  double _flingSimYPos = 0;

  @override
  void initState() {
    super.initState();
    _camera = Camera();
    _flingTicker = createTicker(_onFlingTick);
  }

  @override
  void dispose() {
    _flingTicker.dispose();
    super.dispose();
  }

  void _stopFling() {
    _flingTicker.stop();
    _flingSimX = null;
    _flingSimY = null;
  }

  void _startFling(Offset velocity) {
    _stopFling();
    _flingSimX = FrictionSimulation(_flingFriction, 0, velocity.dx);
    _flingSimY = FrictionSimulation(_flingFriction, 0, velocity.dy);
    _flingSimXPos = 0;
    _flingSimYPos = 0;
    _flingTicker.start();
  }

  void _onFlingTick(Duration elapsed) {
    final simX = _flingSimX;
    final simY = _flingSimY;
    if (simX == null || simY == null) return;

    final t = elapsed.inMicroseconds / 1e6;
    if (simX.isDone(t) && simY.isDone(t)) {
      _stopFling();
      return;
    }

    final newX = simX.x(t);
    final newY = simY.x(t);
    final dx = newX - _flingSimXPos;
    final dy = newY - _flingSimYPos;
    _flingSimXPos = newX;
    _flingSimYPos = newY;

    if (dx == 0 && dy == 0) return;

    setState(() {
      _camera.panByScreenDelta(Offset(dx, dy));
    });
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
        ShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
        _stopFling();
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
          _camera,
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
          _camera,
        );
        setState(() {});
      },
      onPointerHover: (event) {
        _pointerInCanvas = _canvasLocal(event);
        final world = _screenToWorld(event);
        if (world == null) return;
        widget.toolRepository.onPointerHover(
          widget.documentRepository,
          world,
          widget.selectionRepository,
          _isShiftPressed,
          _camera,
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
            _camera,
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
            _camera,
          );
        }
        setState(() {});
      },
      onPointerPanZoomStart: (event) {
        _stopFling();
        _panVelocityTracker =
            VelocityTracker.withKind(PointerDeviceKind.trackpad);
        _panZoomHadSignificantPinch = false;
        _initialZoom = _camera.zoom;
        _initialLocation = _camera.location;
        _pointerInCanvas = _canvasLocal(event);
      },
      onPointerPanZoomEnd: (event) {
        if (_panZoomHadSignificantPinch) return;
        final velocity = _panVelocityTracker.getVelocity().pixelsPerSecond;
        if (velocity.distance < kMinFlingVelocity) return;
        _startFling(velocity);
      },
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        _stopFling();
        final focal = _canvasLocal(event);
        if (focal == null) return;
        setState(() {
          final factor = math.exp(-event.scrollDelta.dy * 0.002);
          _camera.zoomToward(focal, 1 / factor);
        });
      },
      onPointerPanZoomUpdate: (event) {
        if (!event.synthesized) {
          _panVelocityTracker.addPosition(event.timeStamp, event.pan);
        }
        if ((event.scale - 1.0).abs() > _pinchScaleThreshold) {
          _panZoomHadSignificantPinch = true;
        }
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
        child: ViewportToolCursor(
          documentRepository: widget.documentRepository,
          selectionRepository: widget.selectionRepository,
          toolRepository: widget.toolRepository,
          camera: _camera,
          canvasKey: _canvasKey,
          child: DocumentCanvas(
            key: _canvasKey,
            documentRepository: widget.documentRepository,
            toolRepository: widget.toolRepository,
            camera: _camera,
            selectedFeatures: widget.selectedFeatures,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/models/camera.dart';
import '../theme/squiggle_colors.dart';
import 'document_canvas.dart';
import 'viewport_tool_cursor.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({
    super.key,
    required this.context,
    required this.imageRepository,
  });

  final EditorContext context;
  final ImageRepository imageRepository;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport>
    with SingleTickerProviderStateMixin {
  static const _flingFriction = 0.135;
  static const _pinchScaleThreshold = 0.02;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

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

  Camera get _camera => widget.context.camera;

  @override
  void initState() {
    super.initState();
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

    _camera.panByScreenDelta(Offset(dx, dy));
    widget.context.notifyViewportChanged();
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

  bool get _isAltPressed => HardwareKeyboard.instance.isAltPressed;

  void _resetPointerState() {
    _isPrimaryDragging = false;
    _pointerInCanvas = null;
    _stopFling();
  }

  Widget _buildCanvasLayer({required bool canvasInteractionsEnabled}) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!canvasInteractionsEnabled) return;
        ShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
        _stopFling();
        if (event.buttons != kPrimaryButton) return;
        final world = _screenToWorld(event);
        if (world == null) return;
        _isPrimaryDragging = true;
        _pointerInCanvas = _canvasLocal(event);
        widget.context.tool.onPointerDown(
          widget.context,
          world,
          _camera,
          isShiftPressed: _isShiftPressed,
          isAltPressed: _isAltPressed,
        );
      },
      onPointerMove: (event) {
        if (!canvasInteractionsEnabled) return;
        _pointerInCanvas = _canvasLocal(event);
        if (!_isPrimaryDragging) return;
        final world = _screenToWorld(event);
        if (world == null) return;
        widget.context.tool.onPointerMove(
          widget.context,
          world,
          _camera,
          isShiftPressed: _isShiftPressed,
          isAltPressed: _isAltPressed,
        );
      },
      onPointerHover: (event) {
        if (!canvasInteractionsEnabled) return;
        _pointerInCanvas = _canvasLocal(event);
        final world = _screenToWorld(event);
        if (world == null) return;
        widget.context.tool.onPointerHover(
          widget.context,
          world,
          _camera,
          isShiftPressed: _isShiftPressed,
          isAltPressed: _isAltPressed,
        );
      },
      onPointerUp: (event) {
        if (!canvasInteractionsEnabled) return;
        if (!_isPrimaryDragging) return;
        _isPrimaryDragging = false;
        final world = _screenToWorld(event);
        if (world != null) {
          widget.context.tool.onPointerUp(
            widget.context,
            world,
            _camera,
            isShiftPressed: _isShiftPressed,
            isAltPressed: _isAltPressed,
          );
        }
      },
      onPointerCancel: (event) {
        if (!canvasInteractionsEnabled) return;
        if (!_isPrimaryDragging) return;
        _isPrimaryDragging = false;
        final world = _screenToWorld(event);
        if (world != null) {
          widget.context.tool.onPointerUp(
            widget.context,
            world,
            _camera,
            isShiftPressed: _isShiftPressed,
            isAltPressed: _isAltPressed,
          );
        }
      },
      onPointerPanZoomStart: (event) {
        if (!canvasInteractionsEnabled) return;
        _stopFling();
        _panVelocityTracker =
            VelocityTracker.withKind(PointerDeviceKind.trackpad);
        _panZoomHadSignificantPinch = false;
        _initialZoom = _camera.zoom;
        _initialLocation = _camera.location;
        _pointerInCanvas = _canvasLocal(event);
      },
      onPointerPanZoomEnd: (event) {
        if (!canvasInteractionsEnabled) return;
        if (_panZoomHadSignificantPinch) return;
        final velocity = _panVelocityTracker.getVelocity().pixelsPerSecond;
        if (velocity.distance < kMinFlingVelocity) return;
        _startFling(velocity);
      },
      onPointerSignal: (event) {
        if (!canvasInteractionsEnabled) return;
        if (event is! PointerScrollEvent) return;
        _stopFling();
        final focal = _canvasLocal(event);
        if (focal == null) return;
        final factor = math.exp(-event.scrollDelta.dy * 0.002);
        _camera.zoomToward(focal, 1 / factor);
        widget.context.notifyViewportChanged();
      },
      onPointerPanZoomUpdate: (event) {
        if (!canvasInteractionsEnabled) return;
        if (!event.synthesized) {
          _panVelocityTracker.addPosition(event.timeStamp, event.pan);
        }
        if ((event.scale - 1.0).abs() > _pinchScaleThreshold) {
          _panZoomHadSignificantPinch = true;
        }
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
        widget.context.notifyViewportChanged();
      },
      child: Container(
        key: _viewportKey,
        color: SquiggleColors.base,
        child: ViewportToolCursor(
          context: widget.context,
          canvasKey: _canvasKey,
          child: DocumentCanvas(
            key: _canvasKey,
            context: widget.context,
            imageRepository: widget.imageRepository,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TextEditBloc, TextEditState>(
      listenWhen: (previous, current) =>
          current is TextEditOpen && previous is! TextEditOpen,
      listener: (context, state) => _resetPointerState(),
      child: BlocBuilder<TextEditBloc, TextEditState>(
        builder: (context, textEditState) {
          return LayoutBuilder(
            builder: (context, constraints) {
              widget.context.viewportSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return _buildCanvasLayer(
                canvasInteractionsEnabled: textEditState is! TextEditOpen,
              );
            },
          );
        },
      ),
    );
  }
}

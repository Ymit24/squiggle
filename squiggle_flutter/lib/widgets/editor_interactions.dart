import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'fling_controller.dart';

class EditorInteractions extends StatefulWidget {
  const EditorInteractions({
    super.key,
    required this.child,
    required this.context,
    required this.canvasKey,
    required this.imageRepository,
    required this.canvasInteractionsEnabled,
  });

  final Widget child;
  final GlobalKey canvasKey;
  final EditorContext context;
  final ImageRepository imageRepository;
  final bool canvasInteractionsEnabled;

  @override
  State<EditorInteractions> createState() => _EditorInteractionsState();
}

class _EditorInteractionsState extends State<EditorInteractions>
    with SingleTickerProviderStateMixin {
  late final FlingController _flingController;

  Camera get _camera => widget.context.camera;

  @override
  void initState() {
    super.initState();
    _flingController = FlingController(vsync: this, onPan: _onFlingPan);
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  void _onFlingPan(Offset delta) {
    _camera.panByScreenDelta(delta);
    widget.context.notifyViewportChanged();
  }

  void _resetPointerState() {
    _isPrimaryDragging = false;
    _pointerInCanvas = null;
    _flingController.stop();
  }

  static const _pinchScaleThreshold = 0.02;

  double _initialZoom = 1.0;
  Offset _initialLocation = Offset.zero;
  Offset? _pointerInCanvas;
  bool _isPrimaryDragging = false;
  bool _isSecondaryDragging = false;
  bool _panZoomHadSignificantPinch = false;

  VelocityTracker _panVelocityTracker = VelocityTracker.withKind(
    PointerDeviceKind.trackpad,
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<TextEditBloc, TextEditState>(
      listenWhen: (previous, current) =>
          current is TextEditOpen && previous is! TextEditOpen,
      listener: (context, state) => _resetPointerState(),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (!widget.canvasInteractionsEnabled) return;

          if (event.buttons == kPrimaryButton) {
            _onLeftPointerDown(event);
          } else if (event.buttons == kSecondaryButton) {
            _onRightPointerDown(event);
          }
        },
        onPointerMove: (event) {
          if (!widget.canvasInteractionsEnabled) return;

          // TODO: This sucks for state machine
          if (_isPrimaryDragging) {
            _onLeftPointerUpdate(event);
          } else if (_isSecondaryDragging) {
            _onRightPointerUpdate(event);
          }
        },
        onPointerHover: (event) {
          if (!widget.canvasInteractionsEnabled) return;
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
          if (!widget.canvasInteractionsEnabled) return;

          // TODO: This sucks for state machine
          if (_isPrimaryDragging) {
            _onLeftPointerUp(event);
          } else if (_isSecondaryDragging) {
            _onRightPointerUp(event);
          }
        },
        onPointerCancel: (event) {
          if (!widget.canvasInteractionsEnabled) return;
          // TODO: This sucks for state machine
          if (_isPrimaryDragging) {
            _onLeftPointerCancel(event);
          } else if (_isSecondaryDragging) {
            _onRightPointerCancel(event);
          }
        },
        onPointerPanZoomStart: (event) {
          if (!widget.canvasInteractionsEnabled) return;
          _flingController.stop();
          _panVelocityTracker = VelocityTracker.withKind(
            PointerDeviceKind.trackpad,
          );
          _panZoomHadSignificantPinch = false;
          _initialZoom = _camera.zoom;
          _initialLocation = _camera.location;
          _pointerInCanvas = _canvasLocal(event);
        },
        onPointerPanZoomEnd: (event) {
          if (!widget.canvasInteractionsEnabled) return;
          if (_panZoomHadSignificantPinch) return;
          final velocity = _panVelocityTracker.getVelocity().pixelsPerSecond;
          if (velocity.distance < kMinFlingVelocity) return;
          _flingController.fling(velocity);
        },
        onPointerSignal: (event) {
          if (!widget.canvasInteractionsEnabled) return;
          if (event is! PointerScrollEvent) return;
          _flingController.stop();
          final focal = _canvasLocal(event);
          if (focal == null) return;
          final factor = math.exp(-event.scrollDelta.dy * 0.002);
          _camera.zoomToward(focal, 1 / factor);
          widget.context.notifyViewportChanged();
        },
        onPointerPanZoomUpdate: (event) {
          if (!widget.canvasInteractionsEnabled) return;
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
        child: widget.child,
      ),
    );
  }

  Offset? _canvasLocal(PointerEvent event) {
    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
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

  void _onLeftPointerDown(PointerDownEvent event) {
    ShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
    _flingController.stop();

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
  }

  void _onLeftPointerUpdate(PointerMoveEvent event) {
    _pointerInCanvas = _canvasLocal(event);

    final world = _screenToWorld(event);
    if (world == null) return;

    widget.context.tool.onPointerMove(
      widget.context,
      world,
      _camera,
      isShiftPressed: _isShiftPressed,
      isAltPressed: _isAltPressed,
    );
  }

  void _onLeftPointerUp(PointerUpEvent event) {
    _isPrimaryDragging = false;

    final world = _screenToWorld(event);
    if (world == null) return;

    widget.context.tool.onPointerUp(
      widget.context,
      world,
      _camera,
      isShiftPressed: _isShiftPressed,
      isAltPressed: _isAltPressed,
    );
  }

  void _onLeftPointerCancel(PointerCancelEvent event) {
    _isPrimaryDragging = false;

    final world = _screenToWorld(event);
    if (world == null) return;

    widget.context.tool.onPointerUp(
      widget.context,
      world,
      _camera,
      isShiftPressed: _isShiftPressed,
      isAltPressed: _isAltPressed,
    );
  }

  void _onRightPointerDown(PointerDownEvent event) {
    ShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
    _flingController.stop();

    _isSecondaryDragging = true;

    print("Starting right mouse down at ${event.position}");
  }

  void _onRightPointerUpdate(PointerMoveEvent event) {
    if (event.synthesized) return;

    _camera.panByScreenDelta(event.delta);
    widget.context.notifyViewportChanged();
    print("move t=${event.timeStamp.inMilliseconds} pos=${event.position}");
    print("Event: ${event.delta} and position: ${event.position}");
  }

  void _onRightPointerUp(PointerUpEvent event) {
    _isSecondaryDragging = false;
  }

  void _onRightPointerCancel(PointerCancelEvent event) {
    _isSecondaryDragging = false;
  }
}

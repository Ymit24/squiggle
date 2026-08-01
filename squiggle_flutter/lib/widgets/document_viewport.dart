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
import '../theme/squiggle_colors.dart';
import 'document_canvas.dart';
import 'fling_controller.dart';
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
    _flingController.stop();
  }

  Widget _buildCanvasLayer({required bool canvasInteractionsEnabled}) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!canvasInteractionsEnabled) return;
        ShortcutsScope.maybeOf(context)?.requestShortcutsFocus();
        _flingController.stop();
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
        _flingController.stop();
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
        _flingController.fling(velocity);
      },
      onPointerSignal: (event) {
        if (!canvasInteractionsEnabled) return;
        if (event is! PointerScrollEvent) return;
        _flingController.stop();
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

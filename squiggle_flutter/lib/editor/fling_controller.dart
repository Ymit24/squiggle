import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Drives inertial camera panning ("fling") after a gesture ends.
///
/// Owns the [Ticker] and friction simulation; reports each frame's screen-space
/// delta through [onPan] so the caller decides how to apply it (e.g. pan the
/// camera).
class FlingController {
  FlingController({
    required TickerProvider vsync,
    required this.onPan,
    this.friction = 0.135,
  }) {
    _ticker = vsync.createTicker(_onTick);
  }

  final void Function(Offset delta) onPan;
  final double friction;
  late final Ticker _ticker;

  FrictionSimulation? _simX;
  FrictionSimulation? _simY;
  double _simXPos = 0;
  double _simYPos = 0;

  bool get isActive => _ticker.isActive;

  /// Restarts the fling with a new release [velocity] in pixels/second.
  void fling(Offset velocity) {
    stop();
    _simX = FrictionSimulation(friction, 0, velocity.dx);
    _simY = FrictionSimulation(friction, 0, velocity.dy);
    _simXPos = 0;
    _simYPos = 0;
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
    _simX = null;
    _simY = null;
  }

  void _onTick(Duration elapsed) {
    final simX = _simX;
    final simY = _simY;
    if (simX == null || simY == null) return;

    final t = elapsed.inMicroseconds / 1e6;
    if (simX.isDone(t) && simY.isDone(t)) {
      stop();
      return;
    }

    final newX = simX.x(t);
    final newY = simY.x(t);
    final dx = newX - _simXPos;
    final dy = newY - _simYPos;
    _simXPos = newX;
    _simYPos = newY;

    if (dx != 0 || dy != 0) onPan(Offset(dx, dy));
  }

  void dispose() => _ticker.dispose();
}

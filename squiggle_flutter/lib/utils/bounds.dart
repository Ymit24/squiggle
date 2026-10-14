import 'dart:math' as math;
import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/utils/vector2.dart';

class WorldVector2 extends Vector2 {
  WorldVector2(super.x, super.y);

  ScreenVector2 toScreen(Camera camera) {
    throw UnimplementedError();
  }

  LocalVector2 toLocal(WorldVector2 parent) {
    throw UnimplementedError();
  }
}

class LocalVector2 extends Vector2 {
  LocalVector2(super.x, super.y);
}

class ScreenVector2 extends Vector2 {
  ScreenVector2(super.x, super.y);
}

class Bounds {
  Bounds({required this.origin, required this.size, required this.angleRads});

  Vector2 origin;
  Vector2 size;

  double angleRads;

  Rect getAxisAlignedBounds() {
    final cosAngle = math.cos(angleRads).abs();
    final sinAngle = math.sin(angleRads).abs();
    final halfWidth = (size.x * cosAngle + size.y * sinAngle) / 2;
    final halfHeight = (size.x * sinAngle + size.y * cosAngle) / 2;
    final centerX = origin.x + size.x / 2;
    final centerY = origin.y + size.y / 2;

    return Rect.fromLTRB(
      centerX - halfWidth,
      centerY - halfHeight,
      centerX + halfWidth,
      centerY + halfHeight,
    );
  }

  static Bounds envelope(Iterable<Bounds> bounds) {
    if (bounds.isEmpty) {
      throw ArgumentError.value(bounds, 'bounds', 'Must not be empty');
    }

    final envelope = bounds
        .map((bound) => bound.getAxisAlignedBounds())
        .reduce((a, b) => a.expandToInclude(b));

    return Bounds(
      origin: Vector2(envelope.left, envelope.top),
      size: Vector2(envelope.width, envelope.height),
      angleRads: 0,
    );
  }
}

class WorldBounds extends Bounds {
  WorldBounds({
    required super.origin,
    required super.size,
    required super.angleRads,
  });
}

class LocalBounds extends Bounds {
  LocalBounds({
    required super.origin,
    required super.size,
    required super.angleRads,
  });
}

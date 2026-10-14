import 'dart:math' as math;

class Vector2 {
  Vector2(this.x, this.y);

  factory Vector2.zero() {
    return Vector2(0, 0);
  }

  double x;
  double y;

  double get lengthSquared => x * x + y * y;

  double get length => math.sqrt(lengthSquared);

  Vector2 normalized() {
    final magnitude = length;
    if (magnitude == 0) {
      return Vector2.zero();
    }
    return this * (1 / magnitude);
  }

  double distanceToSquared(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double distanceTo(Vector2 other) {
    return math.sqrt(distanceToSquared(other));
  }

  Vector2 perpendicular() {
    return Vector2(-y, x);
  }

  void rotateAround(Vector2 pivot, double angleRads) {
    final dx = x - pivot.x;
    final dy = y - pivot.y;
    final cosAngle = math.cos(angleRads);
    final sinAngle = math.sin(angleRads);

    x = pivot.x + dx * cosAngle - dy * sinAngle;
    y = pivot.y + dx * sinAngle + dy * cosAngle;
  }

  Vector2 operator +(Vector2 other) {
    return Vector2(x + other.x, y + other.y);
  }

  Vector2 operator -(Vector2 other) {
    return Vector2(x - other.x, y - other.y);
  }

  Vector2 operator *(double scaler) {
    return Vector2(x * scaler, y * scaler);
  }

  double dot(Vector2 other) {
    return x * other.x + y * other.y;
  }

  double cross2D(Vector2 other) {
    return x * other.y - y * other.x;
  }
}

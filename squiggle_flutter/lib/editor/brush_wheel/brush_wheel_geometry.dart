import 'dart:math' as math;
import 'dart:ui';

/// Layout of the brush wheel in logical pixels, relative to its center.
///
/// Slot 0 sits at 12 o'clock and slots proceed clockwise, so slot order
/// matches brush order and the Cmd/Ctrl+number shortcuts.
abstract final class BrushWheelGeometry {
  /// Pointer distances below this are the cancel dead zone.
  static const innerRadius = 26.0;

  /// Pointer distances beyond this are outside the wheel and cancel.
  static const outerRadius = 110.0;

  /// Distance from the center to each slot's center.
  static const slotRadius = 76.0;
  static const slotSize = 50.0;
  static const hubSize = 44.0;

  /// Space below the disc reserved for the name label.
  static const labelGap = 10.0;
  static const labelHeight = 28.0;

  static const discSize = Size.square(outerRadius * 2);
  static const size = Size(
    outerRadius * 2,
    outerRadius * 2 + labelGap + labelHeight,
  );

  static double sweep(int count) => 2 * math.pi / count;

  /// Angle of a slot's center, measured clockwise from the positive x axis.
  static double slotAngle(int index, int count) =>
      -math.pi / 2 + index * sweep(count);

  static Offset slotCenter(int index, int count) {
    final angle = slotAngle(index, count);
    return Offset(math.cos(angle), math.sin(angle)) * slotRadius;
  }

  /// The slot under [offset] from the wheel center, or null in the dead zone
  /// and outside the disc.
  static int? slotAt(Offset offset, int count) {
    if (count == 0) return null;
    final distance = offset.distance;
    if (distance < innerRadius || distance > outerRadius) return null;
    final step = sweep(count);
    final fromTop = (offset.direction + math.pi / 2 + step / 2) % (2 * math.pi);
    return (fromTop ~/ step) % count;
  }

  /// Keeps the whole wheel and its label inside [viewport], when it fits.
  static Offset clampCenter(
    Offset pointer,
    Size viewport, {
    double margin = 8,
  }) {
    double clampAxis(double value, double before, double after, double extent) {
      final min = before + margin;
      final max = extent - after - margin;
      if (min > max) return extent / 2;
      return value.clamp(min, max);
    }

    return Offset(
      clampAxis(pointer.dx, outerRadius, outerRadius, viewport.width),
      clampAxis(
        pointer.dy,
        outerRadius,
        size.height - outerRadius,
        viewport.height,
      ),
    );
  }
}

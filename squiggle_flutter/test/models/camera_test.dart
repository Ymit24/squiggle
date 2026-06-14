import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/camera.dart';

void main() {
  test('screenToWorld and worldToScreen round-trip', () {
    final camera = Camera(location: const Offset(100, 200), zoom: 2.0);

    const screen = Offset(50, 75);
    final world = camera.screenToWorld(screen);
    final roundTrip = camera.worldToScreen(world);

    expect(roundTrip.dx, closeTo(screen.dx, 0.001));
    expect(roundTrip.dy, closeTo(screen.dy, 0.001));
  });
}

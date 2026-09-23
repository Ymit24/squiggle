import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  test('screenToWorld and worldToScreen round-trip', () {
    final camera = Camera(location: const Offset(100, 200), zoom: 2.0);

    const screen = Offset(50, 75);
    final world = camera.screenToWorld(screen);
    final roundTrip = camera.worldToScreen(world);

    expect(roundTrip.dx, closeTo(screen.dx, 0.001));
    expect(roundTrip.dy, closeTo(screen.dy, 0.001));
  });

  test('screenToWorldBounds converts origin and size', () {
    final camera = Camera(location: const Offset(100, 200), zoom: 2.0);

    const screenBounds = Rect.fromLTWH(10, 20, 50, 75);

    expect(
      camera.screenToWorldBounds(screenBounds),
      const Rect.fromLTWH(120, 240, 100, 150),
    );
  });

  test('getNodesInViewport uses the camera world bounds', () {
    final visible = Feature(
      origin: const Offset(120, 220),
      size: const Size(10, 10),
      kind: FeatureKindRectangle(),
    );
    final hidden = Feature(
      origin: const Offset(400, 400),
      size: const Size(10, 10),
      kind: FeatureKindRectangle(),
    );
    final document = Document.fromFeatures([visible, hidden]);
    final camera = Camera(location: const Offset(100, 200), zoom: 2);

    expect(camera.getNodesInViewport(document, const Size(100, 50)), [visible]);
    expect(camera.getNodesInViewport(document, Size.zero), isEmpty);
  });
}

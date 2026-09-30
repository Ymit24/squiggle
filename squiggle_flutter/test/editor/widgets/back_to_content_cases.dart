import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/widgets/back_to_content.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  test('jumps to the closest node and cancels viewport motion', () {
    final nearby = Feature(
      origin: const Offset(300, 200),
      size: const Size(20, 20),
      kind: FeatureKindRectangle(),
    );
    final context =
        EditorContext(
            document: Document.fromFeatures([
              Feature(
                origin: const Offset(-1000, -1000),
                size: const Size(20, 20),
                kind: FeatureKindRectangle(),
              ),
              nearby,
            ]),
          )
          ..viewportSize = const Size(200, 100)
          ..camera.location = const Offset(400, 300);
    var motionCancelled = false;
    context.attachViewportMotionCanceller(() => motionCancelled = true);

    jumpBackToContent(context);

    expect(motionCancelled, isTrue);
    expect(context.camera.location, const Offset(210, 160));
  });

  test('does nothing when the document is empty', () {
    final context = EditorContext(document: Document())
      ..viewportSize = const Size(200, 100)
      ..camera.location = const Offset(10, 20);

    jumpBackToContent(context);

    expect(context.camera.location, const Offset(10, 20));
  });
}

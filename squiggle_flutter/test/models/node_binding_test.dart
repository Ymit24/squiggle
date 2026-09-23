import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/group.dart';

void main() {
  Feature rectangle(Offset origin) => Feature(
    origin: origin,
    size: const Size(100, 100),
    kind: FeatureKindRectangle(),
  );
  Feature line() => Feature(
    origin: Offset.zero,
    size: Size.zero,
    kind: FeatureKindPolyline([Offset.zero, const Offset(100, 50)]),
  );
  Offset end(Feature feature) {
    final kind = feature.kind as FeatureKindPolyline;
    return feature.origin + kind.localPoints.last;
  }

  test('radial binding follows target movement and history replay', () {
    final target = rectangle(const Offset(200, 0));
    final connector = line();
    final document = Document.fromFeatures([target, connector]);
    final history = History(document: document);

    document.setFeatureBinding(
      connector,
      start: false,
      binding: RadialBinding(target.id, 0),
    );
    document.notifyBoundFeatures(target);
    expect(end(connector), const Offset(300, 50));
    expect(target.boundFeatureIds, contains(connector.id));

    history.run('Move', (edit) {
      edit.update(
        target,
        (node) => node.editGeometry(
          (geometry) => geometry.origin = const Offset(250, 0),
        ),
      );
    });
    expect(end(connector), const Offset(350, 50));

    history.undo();
    expect(end(connector), const Offset(300, 50));
    history.redo();
    expect(end(connector), const Offset(350, 50));

    final restored = Document.fromDataModel(document.toDataModel());
    final restoredLine = restored.featureById(connector.id)!;
    expect(
      (restoredLine.kind as FeatureKindPolyline).endBinding?.targetId,
      target.id,
    );
    expect(end(restoredLine), const Offset(350, 50));
  });

  test('group movement updates bindings to descendants', () {
    final child = rectangle(const Offset(10, 0));
    final group = Group(origin: const Offset(200, 0), children: [child]);
    final connector = line();
    final document = Document();
    document.addNodes([group, connector]);
    document.setFeatureBinding(
      connector,
      start: false,
      binding: RadialBinding(child.id, 0),
    );
    document.notifyBoundFeatures(child);
    expect(end(connector), const Offset(310, 50));

    group.editGeometry((edit) => edit.origin = const Offset(250, 0));
    expect(end(connector), const Offset(360, 50));
  });

  test('child resize updates bindings to ancestor group once', () {
    final child = rectangle(const Offset(10, 0));
    final group = Group(origin: const Offset(200, 0), children: [child]);
    final connector = line();
    final document = Document();
    document.addNodes([group, connector]);
    document.setFeatureBinding(
      connector,
      start: false,
      binding: RadialBinding(group.id, 0),
    );
    document.notifyBoundFeatures(group);
    expect(end(connector), const Offset(310, 50));

    child.resize(const Rect.fromLTWH(10, 0, 150, 100));
    expect(end(connector), const Offset(360, 50));
  });

  test('both ends can bind to one target and detach separately', () {
    final target = rectangle(const Offset(200, 0));
    final connector = line();
    final document = Document.fromFeatures([target, connector]);
    document.setFeatureBinding(
      connector,
      start: true,
      binding: RadialBinding(target.id, math.pi),
    );
    document.setFeatureBinding(
      connector,
      start: false,
      binding: RadialBinding(target.id, 0),
    );
    expect(target.boundFeatureIds, {connector.id});

    document.setFeatureBinding(connector, start: true);
    expect(target.boundFeatureIds, {connector.id});
    document.setFeatureBinding(connector, start: false);
    expect(target.boundFeatureIds, isEmpty);
  });

  test('inspector changes that affect bounds notify bound features', () {
    final target = Feature(
      origin: const Offset(200, 0),
      size: Size.zero,
      kind: FeatureKindPolyline([
        Offset.zero,
        const Offset(100, 0),
      ], strokeWidth: 2),
    );
    final connector = line();
    final document = Document.fromFeatures([target, connector]);
    document.setFeatureBinding(
      connector,
      start: false,
      binding: RadialBinding(target.id, 0),
    );
    document.notifyBoundFeatures(target);
    expect(end(connector).dx, 301);

    InspectorField.byKeyForFeatures([target])['strokeWidth']!.apply(20.0);
    expect(end(connector).dx, 310);
  });
}

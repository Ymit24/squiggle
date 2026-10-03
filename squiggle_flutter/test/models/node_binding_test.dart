import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  Feature rectangle(Offset origin, {NodeId id = noId}) => Feature(
    id: id,
    origin: origin,
    size: const Size(100, 100),
    kind: FeatureKindRectangle(),
  );
  Feature line({NodeBinding? start, NodeBinding? end}) => Feature(
    origin: Offset.zero,
    size: Size.zero,
    kind: FeatureKindPolyline(
      [Offset.zero, const Offset(100, 50)],
      startBinding: start,
      endBinding: end,
    ),
  );
  List<Offset> points(Feature feature) =>
      (feature.kind as FeatureKindPolyline).resolvedPoints(feature);

  test('bound point resolves through movement, history and reload', () {
    final target = rectangle(const Offset(200, 0));
    final connector = line();
    final document = Document.fromFeatures([target, connector]);
    final kind = connector.kind as FeatureKindPolyline;
    kind.endBinding = RadialBinding(target.id, 0);
    final history = History(document: document);

    expect(points(connector).last, const Offset(300, 50));
    expect(connector.origin + kind.localPoints.last, const Offset(100, 50));
    expect(connector.localBounds().right, greaterThan(300));
    expect(connector.hitTest(const Offset(250, 42)), isTrue);

    history.run('Move', (edit) {
      edit.update(target, (feature) => feature.origin = const Offset(250, 0));
    });
    expect(points(connector).last, const Offset(350, 50));
    history.undo();
    expect(points(connector).last, const Offset(300, 50));
    history.redo();
    expect(points(connector).last, const Offset(350, 50));

    final restored = Document.fromDataModel(document.toDataModel());
    expect(
      points(restored.featureById(connector.id)!).last,
      const Offset(350, 50),
    );
  });

  test('nested target follows group movement without line mutation', () {
    final child = rectangle(const Offset(10, 0));
    final group = Group(origin: const Offset(200, 0), children: [child]);
    final connector = line();
    final document = Document();
    document.addNodes([group, connector]);
    (connector.kind as FeatureKindPolyline).endBinding = RadialBinding(
      child.id,
      0,
    );
    expect(points(connector).last, const Offset(310, 50));

    group.origin = const Offset(250, 0);
    expect(points(connector).last, const Offset(360, 50));
  });

  test('only eligible feature kinds are binding targets', () {
    final shape = rectangle(const Offset(200, 0));
    final nested = rectangle(const Offset(0, 0));
    final otherChild = rectangle(const Offset(200, 0));
    final group = Group(
      origin: const Offset(400, 0),
      children: [nested, otherChild],
    );
    final connector = line();
    final document = Document();
    document.addNodes([shape, group, connector]);

    expect(document.bindingTargetAt(const Offset(250, 50)), same(shape));
    expect(document.bindingTargetAt(const Offset(450, 50)), same(nested));
    expect(document.bindingTargetAt(const Offset(550, 50)), isNull);
    expect(document.bindingTargetAt(const Offset(50, 25)), isNull);
    expect(connector.kind is BindingTargetCapable, isFalse);
    expect(shape.kind is BindingTargetCapable, isTrue);

    (connector.kind as FeatureKindPolyline).endBinding = RadialBinding(
      group.id,
      0,
    );
    expect(points(connector).last, const Offset(100, 50));
    (connector.kind as FeatureKindPolyline).endBinding = RadialBinding(
      connector.id,
      0,
    );
    expect(points(connector).last, const Offset(100, 50));
  });

  test('both endpoints resolve independently and retain fallbacks', () {
    final target = rectangle(const Offset(200, 0));
    final connector = line();
    Document.fromFeatures([target, connector]);
    final kind = connector.kind as FeatureKindPolyline;
    kind.startBinding = RadialBinding(target.id, math.pi);
    kind.endBinding = RadialBinding(target.id, 0);
    expect(points(connector).first.dx, closeTo(200, 0.001));
    expect(points(connector).last, const Offset(300, 50));

    kind.startBinding = null;
    expect(points(connector).first, Offset.zero);
    expect(points(connector).last, const Offset(300, 50));
  });

  test('target geometry changes are visible without notification', () {
    final target = rectangle(const Offset(200, 0));
    final connector = line();
    Document.fromFeatures([target, connector]);
    (connector.kind as FeatureKindPolyline).endBinding = RadialBinding(
      target.id,
      0,
    );
    expect(points(connector).last, const Offset(300, 50));

    target.size = const Size(150, 100);
    expect(points(connector).last, const Offset(350, 50));
  });

  test('missing target uses fallback and resolves when restored', () {
    final targetId = NodeId.newId(2);
    final connector = Feature(
      id: NodeId.newId(1),
      origin: Offset.zero,
      size: Size.zero,
      kind: FeatureKindPolyline([
        Offset.zero,
        const Offset(100, 50),
      ], endBinding: RadialBinding(targetId, 0)),
    );
    final target = rectangle(const Offset(200, 0), id: targetId);
    final document = Document();
    document.addNode(connector);
    expect(points(connector).last, const Offset(100, 50));
    document.addNode(target);
    expect(points(connector).last, const Offset(300, 50));
    document.removeFeature(target.id);
    expect(points(connector).last, const Offset(100, 50));
    document.addNode(target);
    expect(points(connector).last, const Offset(300, 50));
  });

  test('undo and redo restore binding choice', () {
    final first = rectangle(const Offset(200, 0));
    final second = rectangle(const Offset(400, 0));
    final connector = line();
    final document = Document.fromFeatures([first, second, connector]);
    final history = History(document: document);

    history.run('Attach', (edit) {
      edit.update(
        connector,
        (feature) => (feature.kind as FeatureKindPolyline).endBinding =
            RadialBinding(first.id, 0),
      );
    });
    expect(points(connector).last, const Offset(300, 50));
    history.run('Retarget', (edit) {
      edit.update(
        connector,
        (feature) => (feature.kind as FeatureKindPolyline).endBinding =
            RadialBinding(second.id, 0),
      );
    });
    expect(points(connector).last, const Offset(500, 50));
    history.undo();
    expect(points(connector).last, const Offset(300, 50));
    history.redo();
    expect(points(connector).last, const Offset(500, 50));
  });
}

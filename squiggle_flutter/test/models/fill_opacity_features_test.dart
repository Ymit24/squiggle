import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  final factories = <String, FeatureKind Function()>{
    'rectangle': () => FeatureKindRectangle(),
    'circle': () => FeatureKindCircle(),
    'polyline': () => FeatureKindPolyline([
      Offset.zero,
      const Offset(100, 0),
      const Offset(100, 100),
    ]),
  };
  FeatureKind decode(String name, Map<String, dynamic> data) => switch (name) {
    'rectangle' => FeatureKindRectangle.fromDataModel(data),
    'circle' => FeatureKindCircle.fromDataModel(data),
    'polyline' => FeatureKindPolyline.fromDataModel(data),
    _ => throw ArgumentError(name),
  };

  for (final entry in factories.entries) {
    test('${entry.key} fill opacity defaults to fully opaque', () {
      final kind = entry.value() as FillColorCapable;
      expect(kind.fillOpacity, 1);

      final data = (kind as FeatureKind).toDataModel()..remove('fillOpacity');
      expect((decode(entry.key, data) as FillColorCapable).fillOpacity, 1);
    });

    test('${entry.key} fill opacity round trips and clones', () {
      for (final opacity in [0.0, 0.35, 1.0]) {
        final kind = entry.value() as FillColorCapable;
        kind.fillOpacity = opacity;
        expect((kind as FeatureKind).toDataModel()['fillOpacity'], opacity);
        expect(
          (decode(
            entry.key,
            (kind as FeatureKind).toDataModel(),
          ) as FillColorCapable).fillOpacity,
          opacity,
        );
        expect(
          ((kind as FeatureKind).clone() as FillColorCapable).fillOpacity,
          opacity,
        );
      }
    });

    test('${entry.key} fill opacity is clamped when decoded', () {
      final data = entry.value().toDataModel();
      data['fillOpacity'] = 1.5;
      expect((decode(entry.key, data) as FillColorCapable).fillOpacity, 1);
      data['fillOpacity'] = -0.5;
      expect((decode(entry.key, data) as FillColorCapable).fillOpacity, 0);
    });

    test('${entry.key} opacity only affects the painted fill', () {
      final kind = entry.value() as FillColorCapable;
      kind.fillOpacity = 0.5;
      expect(kind.fillPaintColor.a, closeTo(0.5, 0.001));
      expect(kind.hasVisibleFill, isTrue);

      kind.fillOpacity = 0;
      expect(kind.hasVisibleFill, isFalse);
    });
  }
}

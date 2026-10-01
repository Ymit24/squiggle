import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  final factories = <String, FeatureKind Function()>{
    'rectangle': () => FeatureKindRectangle(),
    'circle': () => FeatureKindCircle(),
    'polyline': () => FeatureKindPolyline([Offset.zero, const Offset(100, 0)]),
  };
  FeatureKind decode(String name, Map<String, dynamic> data) => switch (name) {
    'rectangle' => FeatureKindRectangle.fromDataModel(data),
    'circle' => FeatureKindCircle.fromDataModel(data),
    _ => FeatureKindPolyline.fromDataModel(data),
  };

  for (final entry in factories.entries) {
    test('${entry.key} defaults and older documents use solid', () {
      final kind = entry.value();
      expect((kind as StrokeTypeCapable).strokeType, StrokeType.solid);
      final data = kind.toDataModel()..remove('strokeType');
      expect(
        (decode(entry.key, data) as StrokeTypeCapable).strokeType,
        StrokeType.solid,
      );
      data['strokeType'] = 'unknown';
      expect(
        (decode(entry.key, data) as StrokeTypeCapable).strokeType,
        StrokeType.solid,
      );
    });

    for (final type in StrokeType.values) {
      test('${entry.key} round trip and clone preserve $type', () {
        final kind = entry.value();
        (kind as StrokeTypeCapable).strokeType = type;
        expect(kind.toDataModel()['strokeType'], type.name);
        expect(
          (decode(entry.key, kind.toDataModel()) as StrokeTypeCapable)
              .strokeType,
          type,
        );
        expect((kind.clone() as StrokeTypeCapable).strokeType, type);
      });
    }
  }
}

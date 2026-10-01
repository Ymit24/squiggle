import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  final factories = <String, FeatureKind Function()>{
    'rectangle': () => FeatureKindRectangle(),
    'circle': () => FeatureKindCircle(),
  };
  FeatureKind decode(String name, Map<String, dynamic> data) => switch (name) {
    'rectangle' => FeatureKindRectangle.fromDataModel(data),
    'circle' => FeatureKindCircle.fromDataModel(data),
    _ => throw ArgumentError(name),
  };

  for (final entry in factories.entries) {
    test('${entry.key} defaults and older documents use solid', () {
      final kind = entry.value();
      expect((kind as FillTypeCapable).fillType, FillType.solid);
      final data = kind.toDataModel()..remove('fillType');
      expect(
        (decode(entry.key, data) as FillTypeCapable).fillType,
        FillType.solid,
      );
      data['fillType'] = 'unknown';
      expect(
        (decode(entry.key, data) as FillTypeCapable).fillType,
        FillType.solid,
      );
    });

    for (final type in FillType.values) {
      test('${entry.key} round trip and clone preserve $type', () {
        final kind = entry.value();
        (kind as FillTypeCapable).fillType = type;
        expect(kind.toDataModel()['fillType'], type.name);
        expect(
          (decode(entry.key, kind.toDataModel()) as FillTypeCapable).fillType,
          type,
        );
        expect((kind.clone() as FillTypeCapable).fillType, type);
      });
    }
  }
}

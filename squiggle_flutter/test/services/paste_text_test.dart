import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/services/paste_text.dart';

void main() {
  group('createTextFeatureAtCenter', () {
    test('creates centered text feature with measured size', () {
      final feature = createTextFeatureAtCenter(
        contents: 'Hello paste',
        center: const Offset(300, 200),
      );

      expect(feature.kind, isA<FeatureKindText>());
      expect((feature.kind as FeatureKindText).contents, 'Hello paste');
      expect(feature.bounds().center, const Offset(300, 200));
    });
  });
}

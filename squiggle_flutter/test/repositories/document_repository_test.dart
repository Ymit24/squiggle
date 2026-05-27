import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';

void main() {
  group('DocumentRepository', () {
    test('changesStream emits when executeCommand runs', () async {
      final repository = DocumentRepository.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(10, 10)),
      ]);
      final emissions = <void>[];
      final subscription = repository.changesStream.listen(emissions.add);

      repository.executeCommand(
        MoveFeatureCommand(
          repository.document.features.first.id,
          const Offset(5, 5),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, 1);
      await subscription.cancel();
      repository.dispose();
    });
  });
}

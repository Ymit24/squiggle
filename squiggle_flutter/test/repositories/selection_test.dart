import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

void main() {
  group('SelectionRepository', () {
    test('can select features', () {
      final repository = SelectionRepository();
      repository.selectFeature(FeatureId.newId(0));
      expect(repository.selectedFeatures.length, 1);
      expect(repository.selectedFeatures[0], FeatureId.newId(0));
    });

    test('can deselect features', () {
      final repository = SelectionRepository();
      repository.selectFeature(FeatureId.newId(0));
      repository.deselectFeature(FeatureId.newId(0));
      expect(repository.selectedFeatures.length, 0);
    });

    test('can check if a feature is selected', () {
      final repository = SelectionRepository();
      repository.selectFeature(FeatureId.newId(0));
      expect(repository.isFeatureSelected(FeatureId.newId(0)), true);
      expect(repository.isFeatureSelected(FeatureId.newId(1)), false);
    });
  });
}

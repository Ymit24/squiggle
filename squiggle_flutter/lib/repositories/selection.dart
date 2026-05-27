import 'dart:async';

import 'package:squiggle_flutter/models/feature_id.dart';

class SelectionRepository {
  SelectionRepository();

  final List<FeatureId> selectedFeatures = [];

  final StreamController<List<FeatureId>> _selectedFeaturesStreamController =
      StreamController<List<FeatureId>>();

  Stream<List<FeatureId>> get selectedFeaturesStream =>
      _selectedFeaturesStreamController.stream;

  void selectFeature(FeatureId featureId) {
    selectedFeatures.remove(featureId);
    selectedFeatures.add(featureId);
    _update();
  }

  void deselectFeature(FeatureId featureId) {
    selectedFeatures.remove(featureId);
    _update();
  }

  void clearSelection() {
    selectedFeatures.clear();
    _update();
  }

  void setSelection(Iterable<FeatureId> ids) {
    selectedFeatures
      ..clear()
      ..addAll(ids);
    _update();
  }

  void _update() {
    _selectedFeaturesStreamController.add(List.of(selectedFeatures));
  }

  bool isFeatureSelected(FeatureId featureId) {
    return selectedFeatures.contains(featureId);
  }
}

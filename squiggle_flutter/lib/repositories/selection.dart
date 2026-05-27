import 'package:squiggle_flutter/models/feature_id.dart';

class SelectionRepository {
  SelectionRepository();

  final List<FeatureId> selectedFeatures = [];

  void selectFeature(FeatureId featureId) {
    if (!selectedFeatures.contains(featureId)) {
      selectedFeatures.add(featureId);
    }
  }

  void deselectFeature(FeatureId featureId) {
    selectedFeatures.remove(featureId);
  }

  void clearSelection() {
    selectedFeatures.clear();
  }

  bool isFeatureSelected(FeatureId featureId) {
    return selectedFeatures.contains(featureId);
  }
}

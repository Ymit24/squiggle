import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

/// Pure observable state of the current feature selection.
class SelectionModel extends ChangeNotifier {
  final List<FeatureId> _selectedFeatures = [];

  /// Selected feature ids, top-most selection last.
  List<FeatureId> get selectedFeatures => List.unmodifiable(_selectedFeatures);

  bool get isEmpty => _selectedFeatures.isEmpty;

  bool get isNotEmpty => _selectedFeatures.isNotEmpty;

  void selectFeature(FeatureId featureId) {
    _selectedFeatures.remove(featureId);
    _selectedFeatures.add(featureId);
    notifyListeners();
  }

  void deselectFeature(FeatureId featureId) {
    if (_selectedFeatures.remove(featureId)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedFeatures.isEmpty) return;
    _selectedFeatures.clear();
    notifyListeners();
  }

  void setSelection(Iterable<FeatureId> ids) {
    _selectedFeatures
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  bool isFeatureSelected(FeatureId featureId) {
    return _selectedFeatures.contains(featureId);
  }
}

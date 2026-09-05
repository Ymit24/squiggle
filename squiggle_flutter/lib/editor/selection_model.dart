import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

/// Pure observable state of the current feature selection.
class SelectionModel extends ChangeNotifier {
  final List<NodeId> _selectedFeatures = [];

  /// Selected feature ids, top-most selection last.
  List<NodeId> get selectedFeatures => List.unmodifiable(_selectedFeatures);

  bool get isEmpty => _selectedFeatures.isEmpty;

  bool get isNotEmpty => _selectedFeatures.isNotEmpty;

  void selectFeature(NodeId featureId) {
    _selectedFeatures.remove(featureId);
    _selectedFeatures.add(featureId);
    notifyListeners();
  }

  void deselectFeature(NodeId featureId) {
    if (_selectedFeatures.remove(featureId)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedFeatures.isEmpty) return;
    _selectedFeatures.clear();
    notifyListeners();
  }

  void setSelection(Iterable<NodeId> ids) {
    _selectedFeatures
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  bool isFeatureSelected(NodeId featureId) {
    return _selectedFeatures.contains(featureId);
  }
}

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Pure observable state of the current feature selection.
class SelectionModel extends ChangeNotifier {
  final List<NodeId> _selectedNodeIds = [];

  /// Selected feature ids, top-most selection last.
  List<NodeId> get selectedNodeIds => List.unmodifiable(_selectedNodeIds);

  bool get isEmpty => _selectedNodeIds.isEmpty;

  bool get isNotEmpty => _selectedNodeIds.isNotEmpty;

  void selectNode(NodeId nodeId) {
    _selectedNodeIds.remove(nodeId);
    _selectedNodeIds.add(nodeId);
    notifyListeners();
  }

  void deselectNode(NodeId nodeId) {
    if (_selectedNodeIds.remove(nodeId)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedNodeIds.isEmpty) return;
    _selectedNodeIds.clear();
    notifyListeners();
  }

  void setSelection(Iterable<NodeId> ids) {
    _selectedNodeIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  bool isNodeSelected(NodeId nodeId) {
    return _selectedNodeIds.contains(nodeId);
  }
}

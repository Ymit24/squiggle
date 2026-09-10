import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Pure observable state of the current feature selection.
class SelectionModel extends ChangeNotifier {
  final List<NodeId> _selectedNodes = [];

  /// Selected feature ids, top-most selection last.
  List<NodeId> get selectedNodes => List.unmodifiable(_selectedNodes);

  bool get isEmpty => _selectedNodes.isEmpty;

  bool get isNotEmpty => _selectedNodes.isNotEmpty;

  void selectNode(NodeId nodeId) {
    _selectedNodes.remove(nodeId);
    _selectedNodes.add(nodeId);
    notifyListeners();
  }

  void deselectNode(NodeId nodeId) {
    if (_selectedNodes.remove(nodeId)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedNodes.isEmpty) return;
    _selectedNodes.clear();
    notifyListeners();
  }

  void setSelection(Iterable<NodeId> ids) {
    _selectedNodes
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  bool isNodeSelected(NodeId nodeId) {
    return _selectedNodes.contains(nodeId);
  }
}

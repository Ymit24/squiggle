import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  group('SelectionModel', () {
    test('can select features', () {
      final selection = SelectionModel();
      selection.selectNode(NodeId.newId(0));
      expect(selection.selectedNodes.length, 1);
      expect(selection.selectedNodes[0], NodeId.newId(0));
    });

    test('can deselect features', () {
      final selection = SelectionModel();
      selection.selectNode(NodeId.newId(0));
      selection.deselectNode(NodeId.newId(0));
      expect(selection.selectedNodes.length, 0);
    });

    test('can clear selection', () {
      final selection = SelectionModel();
      selection.selectNode(NodeId.newId(0));
      selection.selectNode(NodeId.newId(1));
      selection.clearSelection();
      expect(selection.selectedNodes, isEmpty);
    });

    test('does not duplicate on select', () {
      final selection = SelectionModel();
      final id = NodeId.newId(0);
      selection.selectNode(id);
      selection.selectNode(id);
      expect(selection.selectedNodes.length, 1);
    });

    test('can check if a feature is selected', () {
      final selection = SelectionModel();
      selection.selectNode(NodeId.newId(0));
      expect(selection.isNodeSelected(NodeId.newId(0)), true);
      expect(selection.isNodeSelected(NodeId.newId(1)), false);
    });

    test('emits on each mutation', () async {
      final selection = SelectionModel();
      final id0 = NodeId.newId(0);
      final id1 = NodeId.newId(1);
      final events = <List<NodeId>>[];
      final subscription = notifierChangesStream(selection).listen((_) {
        events.add(selection.selectedNodes);
      });

      selection.selectNode(id0);
      await Future<void>.delayed(Duration.zero);
      selection.selectNode(id1);
      await Future<void>.delayed(Duration.zero);
      selection.deselectNode(id0);
      await Future<void>.delayed(Duration.zero);
      selection.clearSelection();
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        [id0],
        [id0, id1],
        [id1],
        <NodeId>[],
      ]);
      await subscription.cancel();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  group('SelectionModel', () {
    test('can select features', () {
      final selection = SelectionModel();
      selection.selectFeature(NodeId.newId(0));
      expect(selection.selectedFeatures.length, 1);
      expect(selection.selectedFeatures[0], NodeId.newId(0));
    });

    test('can deselect features', () {
      final selection = SelectionModel();
      selection.selectFeature(NodeId.newId(0));
      selection.deselectFeature(NodeId.newId(0));
      expect(selection.selectedFeatures.length, 0);
    });

    test('can clear selection', () {
      final selection = SelectionModel();
      selection.selectFeature(NodeId.newId(0));
      selection.selectFeature(NodeId.newId(1));
      selection.clearSelection();
      expect(selection.selectedFeatures, isEmpty);
    });

    test('does not duplicate on select', () {
      final selection = SelectionModel();
      final id = NodeId.newId(0);
      selection.selectFeature(id);
      selection.selectFeature(id);
      expect(selection.selectedFeatures.length, 1);
    });

    test('can check if a feature is selected', () {
      final selection = SelectionModel();
      selection.selectFeature(NodeId.newId(0));
      expect(selection.isFeatureSelected(NodeId.newId(0)), true);
      expect(selection.isFeatureSelected(NodeId.newId(1)), false);
    });

    test('emits on each mutation', () async {
      final selection = SelectionModel();
      final id0 = NodeId.newId(0);
      final id1 = NodeId.newId(1);
      final events = <List<NodeId>>[];
      final subscription = notifierChangesStream(selection).listen((_) {
        events.add(selection.selectedFeatures);
      });

      selection.selectFeature(id0);
      await Future<void>.delayed(Duration.zero);
      selection.selectFeature(id1);
      await Future<void>.delayed(Duration.zero);
      selection.deselectFeature(id0);
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

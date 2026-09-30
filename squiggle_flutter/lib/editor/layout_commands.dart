import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/node.dart';

void applyNodeLayout(
  EditorContext context,
  List<Node> nodes,
  VoidCallback layout,
) {
  final container = nodes.first.parent;
  if (nodes.any((node) => !identical(node.parent, container))) {
    throw StateError('Selected nodes must share a container');
  }
  context.history.run('Layout selection', (transaction) {
    transaction.watch(nodes);
    layout();
  }, container: container);
}

# Grouping Plan

- Use a runtime `Node` hierarchy: `FeatureNode` (drawable leaf) and `GroupNode` (container).
- `Document` owns the runtime tree; nodes have object parent references and groups own ordered children.
- Every node has a parent-relative `position`; group size/bounds are derived from descendants.
- Render and hit-test recursively in sibling z-order.
- Grouping creates a `GroupNode`, reparents selected nodes, preserves relative order, and converts positions to group-local coordinates.
- Keep serialization framework-neutral with separate `NodeRecord`/feature/group records using IDs and primitive fields; never serialize runtime references.
- Centralize reparenting/group mutations so parent and child references stay synchronized.

```dart
abstract class Node {
  FeatureId id;
  Offset position; // relative to parent
  GroupNode? parent;
  Rect get worldBounds;
}

class FeatureNode extends Node {
  Feature feature;
}

class GroupNode extends Node {
  final List<Node> children; // back-to-front
  // bounds are derived from descendants
}
```

File records use IDs instead of runtime references:

```dart
class GroupRecord {
  int id;
  int? parentId;
  Offset position;
  List<int> childIds;
}
```

Grouping example:

```text
group([circle, label])
  -> create GroupNode(position: selectionBounds.topLeft)
  -> reparent circle and label
  -> convert their positions to group-local coordinates
  -> preserve their sibling order
```

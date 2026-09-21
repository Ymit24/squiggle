import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/node_layout_selector.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/node_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class InspectorLayoutActions extends StatelessWidget {
  const InspectorLayoutActions({
    super.key,
    required this.nodes,
    required this.editorContext,
  });

  final EditorContext editorContext;
  final List<Node> nodes;

  @override
  Widget build(BuildContext context) {
    final spacing = context.squiggleTheme.spacing;

    final showAlign = nodes.length >= 2;
    final showDistribute = nodes.length >= 3;

    final widgets = <Widget>[];

    if (showAlign) {
      widgets.add(
        InspectorFieldShell(
          label: "Align",
          child: NodeAlignSelector(
            onAlign: (alignment) {
              _applyOffsets(
                computeAlignmentOffsets(
                  editorContext.document,
                  nodes,
                  alignment,
                ),
              );
            },
          ),
        ),
      );
    }

    if (showDistribute) {
      widgets.add(
        InspectorFieldShell(
          label: "Distribute",
          child: NodeDistributeSelector(
            onDistribute: (distribute) {
              _applyOffsets(
                computeDistributionOffsets(
                  editorContext.document,
                  nodes,
                  distribute,
                ),
              );
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing.panelSectionSpacing,
      children: widgets,
    );
  }

  List<Node> _nodesById(Iterable<NodeId> ids) => [
    for (final id in ids) editorContext.document.requireNodeById(id),
  ];

  void _applyOffsets(Map<NodeId, Offset> offsets) {
    final nodes = _nodesById(offsets.keys);
    if (nodes.isEmpty) return;
    final container = nodes.first.parent;
    if (nodes.any((node) => !identical(node.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }
    editorContext.history.run('Layout selection', (transaction) {
      for (final node in nodes) {
        transaction.update(node, (node) => node.origin += offsets[node.id]!);
      }
    }, container: container);
  }
}

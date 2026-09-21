import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/node_layout_selector.dart';
import 'package:squiggle_flutter/models/node.dart';
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
              _applyLayout(() => alignNodes(nodes, alignment));
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
              _applyLayout(() => distributeNodes(nodes, distribute));
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

  void _applyLayout(VoidCallback layout) {
    final container = nodes.first.parent;
    if (nodes.any((node) => !identical(node.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }
    editorContext.history.run('Layout selection', (transaction) {
      transaction.watch(nodes);
      layout();
    }, container: container);
  }
}

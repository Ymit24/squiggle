import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_fields.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key, required this.editorContext});

  final EditorContext editorContext;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return ListenableBuilder(
      listenable: Listenable.merge([
        editorContext.selection,
        editorContext.history,
      ]),
      builder: (context, _) {
        final selectedNodes = editorContext.selection.selectedNodeIds
            .map((nodeId) => editorContext.document.requireNodeById(nodeId))
            .whereType<Feature>();
        if (selectedNodes.isEmpty) return SizedBox.shrink();

        print("Building inspector.");

        return DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.panelPadding),
              child: InspectorFields(
                editorContext: editorContext,
                features: selectedNodes.toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

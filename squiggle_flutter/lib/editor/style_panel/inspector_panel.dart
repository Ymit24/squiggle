import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
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

        final inspectorFieldWidgets = _buildInspectorFields(
          context,
          editorContext,
          selectedNodes.toList(),
        );

        print("Building inspector.");

        return DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.panelPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...inspectorFieldWidgets
                      .map(
                        (widget) => [
                          widget,
                          SizedBox(height: spacing.panelSectionSpacing),
                        ],
                      )
                      .flattened,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Iterable<InspectorFieldShell> _buildInspectorFields(
  BuildContext context,
  EditorContext editorContext,
  List<Feature> features,
) {
  final callbacksByFieldKey = <String, InspectorField>{};
  for (final capability in features.expand(
    (feature) => feature.kind.buildInspectorFields(),
  )) {
    final fieldKey = capability.fieldKey;
    if (callbacksByFieldKey.containsKey(fieldKey)) {
      callbacksByFieldKey[fieldKey]!.merge(capability);
    } else {
      callbacksByFieldKey[fieldKey] = capability;
    }
  }
  return callbacksByFieldKey.values.map(
    (capability) => capability.build(context, (result) {
      editorContext.history.run('Inspector Update', (transaction) {
        transaction.watch(features);
        capability.apply(result);
      });
    }),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/brush_picker.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/drawing_inspector_fields.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_fields.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_layout_actions.dart';
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
        editorContext.tool,
        editorContext.brushes,
      ]),
      builder: (context, _) {
        final selectedNodes = editorContext.selection.selectedNodeIds.map(
          (nodeId) => editorContext.document.requireNodeById(nodeId),
        );
        final selectedFeatures = selectedNodes.whereType<Feature>().toList();
        final drawingKind = selectedNodes.isEmpty
            ? editorContext.drawingInspectorKind
            : null;

        if (selectedNodes.isEmpty && drawingKind == null) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: spacing.menuWidth,
          child: DecoratedBox(
            decoration: theme.decorations.floatingPanel(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing.panelPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: spacing.panelSectionSpacing,
                  children: [
                    if (drawingKind != null)
                      BrushPicker(
                        editorContext: editorContext,
                        imageRepository: context.read<ImageRepository>(),
                      ),
                    if (selectedFeatures.isNotEmpty)
                      InspectorFields(
                        editorContext: editorContext,
                        features: selectedFeatures,
                      ),
                    if (drawingKind != null)
                      DrawingInspectorFields(
                        editorContext: editorContext,
                        kind: drawingKind,
                      ),
                    if (selectedNodes.isNotEmpty)
                      InspectorLayoutActions(
                        editorContext: editorContext,
                        nodes: selectedNodes.toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

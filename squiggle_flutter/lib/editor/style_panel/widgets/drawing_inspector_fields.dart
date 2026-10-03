import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_field_reset_button.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DrawingInspectorFields extends StatelessWidget {
  const DrawingInspectorFields({
    super.key,
    required this.editorContext,
    required this.kind,
  });
  final EditorContext editorContext;
  final FeatureKind kind;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: context.squiggleTheme.spacing.panelSectionSpacing,
    children: [
      for (final field in kind.buildInspectorFields())
        _buildField(context, field),
    ],
  );

  Widget _buildField(BuildContext context, InspectorField field) {
    final shell = field.build(
      context,
      (dynamic value) => editorContext.brushes.setField(
        field.fieldKey,
        field.encodeValue(value),
      ),
    );
    return InspectorFieldShell(
      label: shell.label,
      trailing: editorContext.brushes.active.values.containsKey(field.fieldKey)
          ? BrushFieldResetButton(
              onPressed: () => editorContext.brushes.clearField(field.fieldKey),
            )
          : null,
      child: shell.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class InspectorFields extends StatelessWidget {
  const InspectorFields({
    super.key,
    required this.editorContext,
    required this.features,
  });

  final EditorContext editorContext;
  final List<Feature> features;

  @override
  Widget build(BuildContext context) {
    final spacing = context.squiggleTheme.spacing;
    final inspectorFieldByKey = InspectorField.byKeyForFeatures(features);
    final inspectorFieldWidgets = inspectorFieldByKey.values.map(
      (field) => field.build(context, (result) {
        editorContext.history.run('Inspector Update', (transaction) {
          transaction.watch(features);
          field.apply(result);
        });
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing.panelSectionSpacing,
      children: inspectorFieldWidgets.toList(),
    );
  }
}

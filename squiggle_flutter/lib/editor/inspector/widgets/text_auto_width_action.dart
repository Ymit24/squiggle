import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/alignment_swatch.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature.dart';

/// Turns fixed-width text back into auto-width text. Fixed width only comes
/// from dragging, so the inspector offers just the way back.
class TextAutoWidthAction extends StatelessWidget {
  const TextAutoWidthAction({
    super.key,
    required this.editorContext,
    required this.features,
  });

  final EditorContext editorContext;
  final List<Feature> features;

  @override
  Widget build(BuildContext context) => InspectorFieldShell(
    label: 'Width',
    child: Tooltip(
      message: 'Auto width',
      child: AlignmentSwatch(
        icon: Icons.format_size,
        isActive: false,
        enabled: true,
        onPressed: _makeAutoWidth,
      ),
    ),
  );

  /// Whether [features] are all fixed-width text, the only case it applies to.
  static bool appliesTo(List<Feature> features) =>
      features.isNotEmpty &&
      features.every(
        (feature) => switch (feature.kind) {
          FeatureKindText(sizing: TextSizing.fixedWidth) => true,
          _ => false,
        },
      );

  void _makeAutoWidth() {
    editorContext.history.run('Auto Width', (transaction) {
      transaction.watch(features);
      for (final feature in features) {
        (feature.kind as FeatureKindText).makeAutoWidth(feature);
      }
    });
  }
}

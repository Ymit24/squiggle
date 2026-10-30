import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/theme.dart';

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
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return InspectorFieldShell(
      label: 'Width: fixed',
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          style: theme.menuItemStyle().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
            side: WidgetStatePropertyAll(
              BorderSide(color: theme.colors.surface1),
            ),
          ),
          onPressed: _makeAutoWidth,
          icon: const Icon(Icons.format_size, size: 16),
          label: const Text('Fit width to text'),
        ),
      ),
    );
  }

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

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// Closes selected lines into filled shapes, or opens them back up. Closing is
/// geometry rather than style, so it stays out of brush fields.
class PolylineClosedAction extends StatelessWidget {
  const PolylineClosedAction({
    super.key,
    required this.editorContext,
    required this.features,
  });

  final EditorContext editorContext;
  final List<Feature> features;

  Iterable<FeatureKindPolyline> get _kinds =>
      features.map((feature) => feature.kind as FeatureKindPolyline);

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final allClosed = _kinds.every((kind) => kind.isClosed);
    return InspectorFieldShell(
      label: 'Shape',
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          style: theme.menuItemStyle().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
            side: WidgetStatePropertyAll(
              BorderSide(color: theme.colors.surface1),
            ),
          ),
          onPressed: () => _setClosed(!allClosed),
          icon: Icon(allClosed ? Icons.polyline : Icons.pentagon, size: 16),
          label: Text(allClosed ? 'Open shape' : 'Close shape'),
        ),
      ),
    );
  }

  /// Whether [features] are all lines with enough points to close.
  static bool appliesTo(List<Feature> features) =>
      features.isNotEmpty &&
      features.every(
        (feature) => switch (feature.kind) {
          final FeatureKindPolyline kind => kind.canClose,
          _ => false,
        },
      );

  void _setClosed(bool value) {
    editorContext.history.run(value ? 'Close Shape' : 'Open Shape', (
      transaction,
    ) {
      transaction.watch(features);
      for (final feature in features) {
        (feature.kind as FeatureKindPolyline).setClosed(feature, value);
      }
    });
  }
}

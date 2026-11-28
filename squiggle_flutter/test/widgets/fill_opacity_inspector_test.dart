import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/fill_opacity_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_fields.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  testWidgets('fill opacity slider affects fills but not stroke colors', (
    tester,
  ) async {
    final features = [
      for (final kind in <FeatureKind>[
        FeatureKindRectangle(),
        FeatureKindCircle(),
      ])
        Feature(origin: Offset.zero, size: const Size(100, 60), kind: kind),
    ];
    final context = EditorContext(document: Document.fromFeatures(features));
    Iterable<FillColorCapable> kinds() =>
        features.map((feature) => feature.kind as FillColorCapable);
    final strokeColors = features
        .map((feature) => (feature.kind as StrokeColorCapable).strokeColor)
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InspectorFields(editorContext: context, features: features),
          ),
        ),
      ),
    );

    expect(find.byType(FillOpacitySelector), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pump();

    final opacity = kinds().map((kind) => kind.fillOpacity).toList();
    expect(opacity.first, lessThan(1));
    expect(opacity, [opacity.first, opacity.first]);
    expect(
      features.map(
        (feature) => (feature.kind as StrokeColorCapable).strokeColor,
      ),
      strokeColors,
    );
  });
}

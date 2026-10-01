import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_fields.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/stroke_type_selector.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  Finder swatches() => find.descendant(
    of: find.byType(StrokeTypeSelector),
    matching: find.byType(StyleColorSwatch),
  );

  testWidgets('selector shows the active type and selects each option', (
    tester,
  ) async {
    StrokeType? selected;
    await pump(
      tester,
      StrokeTypeSelector(
        activeType: StrokeType.dashed,
        isMixed: false,
        onTypeSelected: (type) => selected = type,
      ),
    );
    expect(
      tester
          .widgetList<StyleColorSwatch>(swatches())
          .map((swatch) => swatch.isActive),
      [false, true, false],
    );
    for (final type in StrokeType.values) {
      await tester.tap(swatches().at(type.index));
      expect(selected, type);
    }
  });

  testWidgets('mixed selection has no active swatch; disabled ignores taps', (
    tester,
  ) async {
    StrokeType? selected;
    await pump(
      tester,
      StrokeTypeSelector(
        activeType: StrokeType.solid,
        isMixed: true,
        enabled: false,
        onTypeSelected: (type) => selected = type,
      ),
    );
    expect(
      tester
          .widgetList<StyleColorSwatch>(swatches())
          .every((swatch) => !swatch.isActive),
      isTrue,
    );
    await tester.tap(swatches().at(1));
    expect(selected, isNull);
  });

  testWidgets(
    'selection inspector updates mixed shapes without changing drawing defaults',
    (tester) async {
      final kinds = <FeatureKind>[
        FeatureKindRectangle(),
        FeatureKindCircle(strokeType: StrokeType.dotted),
        FeatureKindPolyline([
          Offset.zero,
          const Offset(100, 0),
        ], strokeType: StrokeType.dashed),
      ];
      final features = [
        for (final kind in kinds)
          Feature(origin: Offset.zero, size: const Size(100, 60), kind: kind),
      ];
      final context = EditorContext(document: Document.fromFeatures(features));
      List<StrokeType> types() => [
        for (final feature in features)
          (feature.kind as StrokeTypeCapable).strokeType,
      ];
      Future<void> pumpInspector() => pump(
        tester,
        InspectorFields(editorContext: context, features: features),
      );

      await pumpInspector();
      expect(swatches(), findsNWidgets(3));
      expect(
        tester
            .widgetList<StyleColorSwatch>(swatches())
            .every((swatch) => !swatch.isActive),
        isTrue,
      );
      await tester.tap(swatches().at(StrokeType.dotted.index));
      expect(types(), [
        StrokeType.dotted,
        StrokeType.dotted,
        StrokeType.dotted,
      ]);
      await pumpInspector();
      expect(
        tester.widget<StyleColorSwatch>(swatches().at(2)).isActive,
        isTrue,
      );

      context.undo();
      expect(types(), [StrokeType.solid, StrokeType.dotted, StrokeType.dashed]);
      context.redo();
      expect(types(), [
        StrokeType.dotted,
        StrokeType.dotted,
        StrokeType.dotted,
      ]);

      for (final kind in <FeatureKind>[
        FeatureKindRectangle(),
        FeatureKindCircle(),
        FeatureKindPolyline([Offset.zero, const Offset(100, 0)]),
      ]) {
        context.applyInspectorValues(kind);
        expect((kind as StrokeTypeCapable).strokeType, StrokeType.solid);
      }
    },
  );
}

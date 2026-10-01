import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/fill_type_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_fields.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  testWidgets(
    'selection fill choices support undo without changing new shape styles',
    (tester) async {
      final features = [
        for (final kind in <FeatureKind>[
          FeatureKindRectangle(),
          FeatureKindCircle(fillType: FillType.lines),
          FeatureKindPolyline([Offset.zero, const Offset(100, 0)]),
        ])
          Feature(origin: Offset.zero, size: const Size(100, 60), kind: kind),
      ];
      final context = EditorContext(document: Document.fromFeatures(features));
      List<FillType> types() => [
        for (final feature in features.take(2))
          (feature.kind as FillTypeCapable).fillType,
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectorFields(
                editorContext: context,
                features: features,
              ),
            ),
          ),
        ),
      );
      final swatches = find.descendant(
        of: find.byType(FillTypeSelector),
        matching: find.byType(StyleColorSwatch),
      );
      expect(swatches, findsNWidgets(3));
      expect(
        tester
            .widgetList<StyleColorSwatch>(swatches)
            .every((swatch) => !swatch.isActive),
        isTrue,
      );
      for (final type in FillType.values) {
        await tester.tap(swatches.at(type.index));
        expect(types(), [type, type]);
      }
      context.undo();
      expect(types(), [FillType.lines, FillType.lines]);
      context.redo();
      expect(types(), [FillType.crosshatch, FillType.crosshatch]);

      for (final kind in <FeatureKind>[
        FeatureKindRectangle(),
        FeatureKindCircle(),
      ]) {
        context.brushes.active.applyTo(kind);
        expect((kind as FillTypeCapable).fillType, FillType.solid);
      }
      final line = features.last.kind;
      context.brushes.active.applyTo(line);
      expect(
        line.buildInspectorFields().any(
          (field) => field.fieldKey == 'fillType',
        ),
        isFalse,
      );
    },
  );
}

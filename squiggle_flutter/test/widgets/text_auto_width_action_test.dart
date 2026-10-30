import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/text_auto_width_action.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

void main() {
  test('only applies when every selected feature is fixed-width text', () {
    final fixed = newTextFeatureAt(Offset.zero, 'hello', fixedWidth: 300);
    final auto = newTextFeatureAt(Offset.zero, 'hello');
    final shape = Feature(
      origin: Offset.zero,
      size: const Size(10, 10),
      kind: FeatureKindRectangle(),
    );

    expect(TextAutoWidthAction.appliesTo([fixed]), isTrue);
    expect(TextAutoWidthAction.appliesTo([fixed, auto]), isFalse);
    expect(TextAutoWidthAction.appliesTo([fixed, shape]), isFalse);
    expect(TextAutoWidthAction.appliesTo([]), isFalse);
  });

  testWidgets('makes fixed-width text hug its contents, undoably', (
    tester,
  ) async {
    final feature = newTextFeatureAt(Offset.zero, 'hello', fixedWidth: 300);
    final kind = feature.kind as FeatureKindText;
    final context = EditorContext(document: Document.fromFeatures([feature]));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextAutoWidthAction(
            editorContext: context,
            features: [feature],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fit width to text'));

    expect(kind.sizing, TextSizing.auto);
    expect(feature.width, kind.measureContents(fontSize: kind.fontSize).width);

    context.undo();
    final restored = context.document.requireNodeById(feature.id) as Feature;
    expect((restored.kind as FeatureKindText).sizing, TextSizing.fixedWidth);
    expect(restored.width, 300);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

import 'context_menu_grouping_test.dart' show openMenu;

Feature _triangle({bool isClosed = false}) => Feature(
  origin: Offset.zero,
  size: const Size(100, 100),
  kind: FeatureKindPolyline(const [
    Offset.zero,
    Offset(100, 0),
    Offset(100, 100),
  ], isClosed: isClosed),
);

EditorContext _selecting(List<Feature> features) {
  final context = EditorContext(document: Document.fromFeatures(features))
    ..selection.setSelection(features.map((feature) => feature.id));
  addTearDown(context.dispose);
  return context;
}

void main() {
  test('only actions every feature offers are shared', () {
    final fixed = newTextFeatureAt(Offset.zero, 'hello', fixedWidth: 300);
    final auto = newTextFeatureAt(Offset.zero, 'hello');
    List<String> keys(List<Feature> features) => [
      for (final group in FeatureAction.sharedBy(features)) group.first.key,
    ];

    expect(keys([fixed]), ['autoFitText']);
    expect(keys([fixed, auto]), isEmpty);
    expect(keys([fixed, _triangle()]), isEmpty);
    expect(keys([_triangle(), _triangle()]), ['closeShape']);
    expect(keys([_triangle(isClosed: true)]), ['openShape']);
    expect(keys([_triangle(), _triangle(isClosed: true)]), isEmpty);
  });

  testWidgets('closes and reopens selected lines, undoably', (tester) async {
    final line = _triangle();
    final kind = line.kind as FeatureKindPolyline;
    final context = _selecting([line]);

    await openMenu(tester, context);
    expect(find.text('Open Shape'), findsNothing);
    await tester.tap(find.text('Close Shape'));
    await tester.pumpAndSettle();
    expect(kind.isClosed, isTrue);

    await openMenu(tester, context);
    await tester.tap(find.text('Open Shape'));
    await tester.pumpAndSettle();
    expect(kind.isClosed, isFalse);

    context.undo();
    final restored = context.document.requireNodeById(line.id) as Feature;
    expect((restored.kind as FeatureKindPolyline).isClosed, isTrue);
  });

  testWidgets('auto fits fixed-width text, undoably', (tester) async {
    final text = newTextFeatureAt(Offset.zero, 'hello', fixedWidth: 300);
    final kind = text.kind as FeatureKindText;
    final context = _selecting([text]);

    await openMenu(tester, context);
    await tester.tap(find.text('Auto Fit to Text'));
    await tester.pumpAndSettle();
    expect(kind.sizing, TextSizing.auto);
    expect(text.width, kind.measureContents(fontSize: kind.fontSize).width);

    context.undo();
    final restored = context.document.requireNodeById(text.id) as Feature;
    expect((restored.kind as FeatureKindText).sizing, TextSizing.fixedWidth);
    expect(restored.width, 300);
  });
}

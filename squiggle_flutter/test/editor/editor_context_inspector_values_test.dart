import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  test('brush field edits keep the latest value', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindRectangle();

    context.brushes.setField('fillColor', const Color(0xFFFF0000).toARGB32());
    context.brushes.setField('fillColor', const Color(0xFF0000FF).toARGB32());
    context.brushes.active.applyTo(kind);

    expect(kind.fillColor, const Color(0xFF0000FF));
  });

  test('brush application applies a matching field', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindCircle();

    context.brushes.setField('strokeWidth', 5.0);
    context.brushes.active.applyTo(kind);

    expect(kind.strokeWidth, 5.0);
  });

  test('brush application leaves unset fields at their defaults', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindRectangle();
    final originalFillColor = kind.fillColor;

    context.brushes.active.applyTo(kind);

    expect(kind.fillColor, originalFillColor);
  });
}

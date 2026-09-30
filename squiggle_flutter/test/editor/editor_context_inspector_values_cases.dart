import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  test('rememberInspectorValue keeps the latest value', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindRectangle();

    context.rememberInspectorValue('fillColor', const Color(0xFFFF0000));
    context.rememberInspectorValue('fillColor', const Color(0xFF0000FF));
    context.applyInspectorValues(kind);

    expect(kind.fillColor, const Color(0xFF0000FF));
  });

  test('applyInspectorValues applies a matching field', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindCircle();

    context.rememberInspectorValue('strokeWidth', 5.0);
    context.applyInspectorValues(kind);

    expect(kind.strokeWidth, 5.0);
  });

  test('applyInspectorValues leaves defaults when no value is remembered', () {
    final context = EditorContext(document: Document());
    final kind = FeatureKindRectangle();
    final originalFillColor = kind.fillColor;

    context.applyInspectorValues(kind);

    expect(kind.fillColor, originalFillColor);
  });
}

import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  test('all supported inspector fields encode and apply to fresh features', () {
    final sources = <FeatureKind>[
      FeatureKindRectangle(
        strokeColor: const Color(0xFF123456),
        fillColor: const Color(0x88765432),
        fillType: FillType.lines,
        strokeType: StrokeType.dashed,
        strokeWidth: 3,
        labelFontSize: 36,
        labelHorizontalAlignment: TextHorizontalAlignment.right,
        labelVerticalAlignment: TextVerticalAlignment.bottom,
      ),
      FeatureKindCircle(strokeWidth: 16),
      FeatureKindText('Aa', fontSize: 36),
      FeatureKindPolyline(
        [],
        startEndCap: LineEndCap.arrow,
        endEndCap: LineEndCap.arrow,
      ),
    ];
    for (final source in sources) {
      final fields = source.buildInspectorFields().toList();
      final brush = BrushProfile(
        id: 'sample',
        name: 'Sample',
        values: {
          for (final field in fields)
            field.fieldKey: field.encodeValue(field.activeValue),
        },
      );
      final raw = jsonDecode(jsonEncode(brush.toDataModel().toJson()));
      expect(raw['values'], brush.values);
      final FeatureKind target = switch (source) {
        FeatureKindRectangle() => FeatureKindRectangle(),
        FeatureKindCircle() => FeatureKindCircle(),
        FeatureKindText() => FeatureKindText('Unchanged content'),
        FeatureKindPolyline() => FeatureKindPolyline([]),
        _ => throw StateError('Unexpected sample'),
      };
      brush.applyTo(target);
      final applied = {
        for (final field in target.buildInspectorFields())
          field.fieldKey: field.activeValue,
      };
      for (final field in fields) {
        expect(
          applied[field.fieldKey],
          field.activeValue,
          reason: field.fieldKey,
        );
      }
      if (target is FeatureKindText) expect(target.label, 'Unchanged content');
    }
  });

  test('invalid overrides leave defaults and unknown keys survive', () {
    final kind = FeatureKindRectangle();
    final before = kind.toDataModel();
    final brush = BrushProfile(
      id: 'sample',
      name: 'Sample',
      values: {
        'strokeColor': 'orange',
        'fillColor': -1,
        'strokeWidth': -4,
        'fontSize': double.infinity,
        'strokeType': 'future-stroke',
        'fillType': 42,
        'horizontalAlignment': null,
        'verticalAlignment': 'unknown',
        'futureStyle': {
          'nested': ['preserved'],
        },
        'endEndCap': 'arrow',
      },
    );
    brush.applyTo(kind);
    expect(kind.toDataModel(), before);
    expect(brush.toDataModel().values['futureStyle'], {
      'nested': ['preserved'],
    });
    final line = FeatureKindPolyline([]);
    brush.applyTo(line);
    expect(line.endEndCap, LineEndCap.arrow);
    expect(line.strokeWidth, defaultStrokeWidth);
  });
}

import 'dart:ui';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/feature.dart';

/// A sparse set of appearance overrides. Missing fields leave defaults intact.
class BrushProfile {
  BrushProfile({
    required this.id,
    required this.name,
    Map<String, Object?>? values,
  }) : values = Map.of(values ?? {});

  static const scratchId = 'scratch';
  final String id;
  String name;
  final Map<String, Object?> values;
  bool get isScratch => id == scratchId;

  void applyTo(FeatureKind kind) {
    for (final field in kind.buildInspectorFields()) {
      if (values.containsKey(field.fieldKey)) {
        field.applyIfCompatible(values[field.fieldKey]);
      }
    }
  }

  factory BrushProfile.fromDataModel(data.BrushProfile raw) {
    final values = <String, Object?>{};
    for (final entry in raw.values.entries) {
      try {
        final value = _decode(entry.key, entry.value);
        if (value != null) values[entry.key] = value;
      } on Object {
        // An invalid known override must not prevent opening the document.
      }
    }
    return BrushProfile(id: raw.id, name: raw.name, values: values);
  }

  data.BrushProfile toDataModel() => data.BrushProfile(
    id: id,
    name: name,
    values: {
      for (final entry in values.entries) entry.key: _encode(entry.value),
    },
  );

  static Object? _encode(Object? value) => switch (value) {
    Color color => color.toARGB32(),
    Enum value => value.name,
    _ => value,
  };

  // Field keys carry shared semantics across the feature kinds. Unknown keys
  // stay JSON-compatible and survive round trips for forward compatibility.
  static Object? _decode(String key, Object? value) => switch (key) {
    'strokeColor' || 'fillColor' => Color((value as num).toInt()),
    'strokeWidth' || 'fontSize' => _positiveNumber(value),
    'strokeType' => StrokeType.values.byName(value as String),
    'fillType' => FillType.values.byName(value as String),
    'startEndCap' || 'endEndCap' => LineEndCap.values.byName(value as String),
    'horizontalAlignment' => TextHorizontalAlignment.values.byName(
      value as String,
    ),
    'verticalAlignment' => TextVerticalAlignment.values.byName(value as String),
    _ => value,
  };

  static double? _positiveNumber(Object? value) {
    final number = (value as num).toDouble();
    return number.isFinite && number > 0 ? number : null;
  }
}

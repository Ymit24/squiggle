import 'package:squiggle_flutter/models/style_value_serialization.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/font_size_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/stroke_width_selector.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/font_size_preset.dart';
import 'package:squiggle_flutter/models/stroke_width_preset.dart';

class InspectorWidthField extends InspectorField<double> {
  @override
  Object? encodeValue(double value) => value;

  @override
  double decodeValue(Object? raw) => _decodePositiveNumber(raw);

  InspectorWidthField({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onWidthChanged,
  }) : super(values: [value], callbacks: [onWidthChanged]);
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: StrokeWidthSelector(
      activePreset: StrokeWidthPreset.fromWidth(activeValue),
      isMixed: isMixed,
      onPresetSelected: (value) => onUpdate(value.width),
    ),
  );
}

class InspectorFontSizeField extends InspectorField<double> {
  @override
  Object? encodeValue(double value) => value;

  @override
  double decodeValue(Object? raw) => _decodePositiveNumber(raw);

  InspectorFontSizeField({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onFontSizeChanged,
  }) : super(values: [value], callbacks: [onFontSizeChanged]);
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: FontSizeSelector(
      activePreset: FontSizePreset.fromSize(activeValue),
      isMixed: isMixed,
      onPresetSelected: (value) => onUpdate(value.size),
    ),
  );
}

double _decodePositiveNumber(Object? raw) {
  final value = decodeStyleNumber(raw);
  if (value <= 0) throw const FormatException('Expected a positive number.');
  return value;
}

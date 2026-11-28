import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/fill_opacity_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/style_value_serialization.dart';

class InspectorFillOpacityField extends InspectorField<double> {
  InspectorFillOpacityField({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onOpacityChanged,
  }) : super(values: [value], callbacks: [onOpacityChanged]);

  @override
  Object? encodeValue(double value) => value;

  @override
  double decodeValue(Object? raw) =>
      decodeStyleNumber(raw).clamp(0.0, 1.0).toDouble();

  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: FillOpacitySelector(
      opacity: activeValue,
      isMixed: isMixed,
      onChanged: onUpdate,
    ),
  );
}

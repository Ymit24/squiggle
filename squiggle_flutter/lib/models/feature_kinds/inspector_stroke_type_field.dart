import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/stroke_type_selector.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/stroke_type.dart';
import 'package:squiggle_flutter/models/style_value_serialization.dart';

class InspectorStrokeTypeField extends InspectorField<StrokeType> {
  InspectorStrokeTypeField({
    required super.fieldKey,
    required super.label,
    required StrokeType value,
    required ValueChanged<StrokeType> onTypeChanged,
  }) : super(values: [value], callbacks: [onTypeChanged]);
  @override
  Object? encodeValue(StrokeType value) => value.name;

  @override
  StrokeType decodeValue(Object? raw) =>
      decodeStyleEnum(raw, StrokeType.values);

  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(StrokeType) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: StrokeTypeSelector(
      activeType: activeValue,
      isMixed: isMixed,
      onTypeSelected: onUpdate,
    ),
  );
}

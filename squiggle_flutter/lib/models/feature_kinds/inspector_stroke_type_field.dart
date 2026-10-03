import 'package:squiggle_flutter/models/style_value_serialization.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/stroke_type_selector.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/stroke_type.dart';

class InspectorStrokeTypeField extends InspectorField<StrokeType> {
  @override
  Object? encodeValue(StrokeType value) => value.name;

  @override
  StrokeType decodeValue(Object? raw) =>
      decodeStyleEnum(raw, StrokeType.values);

  InspectorStrokeTypeField({
    required super.fieldKey,
    required super.label,
    required StrokeType value,
    required ValueChanged<StrokeType> onTypeChanged,
  }) : super(values: [value], callbacks: [onTypeChanged]);

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

import 'package:squiggle_flutter/models/style_value_serialization.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/fill_type_selector.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/fill_type.dart';

class InspectorFillTypeField extends InspectorField<FillType> {
  @override
  Object? encodeValue(FillType value) => value.name;

  @override
  FillType decodeValue(Object? raw) => decodeStyleEnum(raw, FillType.values);

  InspectorFillTypeField({
    required super.fieldKey,
    required super.label,
    required FillType value,
    required ValueChanged<FillType> onTypeChanged,
  }) : super(values: [value], callbacks: [onTypeChanged]);

  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(FillType) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: FillTypeSelector(
      activeType: activeValue,
      isMixed: isMixed,
      onTypeSelected: onUpdate,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/fill_type_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';
import 'package:squiggle_flutter/models/fill_type.dart';

class InspectorFillTypeField extends InspectorField<FillType> {
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

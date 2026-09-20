import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_row.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';

class InspectorColorField extends InspectorField<Color> {
  InspectorColorField({
    required super.fieldKey,
    required super.label,
    required Color value,
    required ValueChanged<Color> onColorChanged,
  }) : super(values: [value], callbacks: [onColorChanged]);
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(Color) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: ColorRow(
      presets: stylePresets.map((item) => item.strokeColor).toList(),
      activePresetIndex: null,
      noneEnabled: true,
      onPresetSelected: (index) => onUpdate(stylePresets[index].strokeColor),
    ),
  );
}

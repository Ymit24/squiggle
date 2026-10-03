import 'package:squiggle_flutter/models/style_value_serialization.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/color_row.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';

class InspectorColorField extends InspectorField<Color> {
  @override
  Object? encodeValue(Color value) => value.toARGB32();

  @override
  Color decodeValue(Object? raw) => decodeStyleColor(raw);

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

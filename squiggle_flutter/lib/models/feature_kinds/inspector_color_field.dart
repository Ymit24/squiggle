import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_row.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_capability.dart';

class InspectorColorCapability extends InspectorCapability<Color> {
  InspectorColorCapability({
    required super.fieldKey,
    required super.label,
    required Color value,
    required ValueChanged<Color> onColorChanged,
  }) : super(values: [value], callbacks: [onColorChanged]);
  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(Color) onUpdate,
  ) => InspectorCapabilityFieldShell(
    label: label,
    child: ColorRow(
      presets: stylePresets.map((item) => item.strokeColor).toList(),
      activePresetIndex: null,
      noneEnabled: true,
      onPresetSelected: (index) => onUpdate(stylePresets[index].strokeColor),
    ),
  );
}

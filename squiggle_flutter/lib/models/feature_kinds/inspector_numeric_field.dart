import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/font_size_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/stroke_width_selector.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_capability.dart';
import 'package:squiggle_flutter/models/font_size_preset.dart';
import 'package:squiggle_flutter/models/stroke_width_preset.dart';

class InspectorWidthCapability extends InspectorCapability<double> {
  InspectorWidthCapability({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onWidthChanged,
  }) : super(values: [value], callbacks: [onWidthChanged]);
  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) => InspectorCapabilityFieldShell(
    label: label,
    child: StrokeWidthSelector(
      activePreset: StrokeWidthPreset.fromWidth(activeValue),
      isMixed: isMixed,
      onPresetSelected: (value) => onUpdate(value.width),
    ),
  );
}

class InspectorFontSizeCapability extends InspectorCapability<double> {
  InspectorFontSizeCapability({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onFontSizeChanged,
  }) : super(values: [value], callbacks: [onFontSizeChanged]);
  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) => InspectorCapabilityFieldShell(
    label: label,
    child: FontSizeSelector(
      activePreset: FontSizePreset.fromSize(activeValue),
      isMixed: isMixed,
      onPresetSelected: (value) => onUpdate(value.size),
    ),
  );
}

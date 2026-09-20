import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/line_end_cap_selector.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';

class InspectorEndCapField extends InspectorField<LineEndCap> {
  InspectorEndCapField({
    required super.fieldKey,
    required super.label,
    required this.isStart,
    required LineEndCap value,
    required ValueChanged<LineEndCap> onEndCapChanged,
  }) : super(values: [value], callbacks: [onEndCapChanged]);
  final bool isStart;
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(LineEndCap) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: LineEndCapSelector(
      activeEndCap: activeValue,
      isMixed: isMixed,
      isStart: isStart,
      onEndCapSelected: onUpdate,
    ),
  );
}

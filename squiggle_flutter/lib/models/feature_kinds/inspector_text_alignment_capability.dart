import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/text_alignment_selector.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_capability.dart';

class InspectorVerticalTextAlignmentCapability
    extends InspectorCapability<TextVerticalAlignment> {
  InspectorVerticalTextAlignmentCapability({
    required super.fieldKey,
    required super.label,
    required TextVerticalAlignment value,
    required ValueChanged<TextVerticalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);
  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(TextVerticalAlignment) onUpdate,
  ) => InspectorCapabilityFieldShell(
    label: label,
    child: TextVerticalAlignmentSelector(
      activeAlignment: activeValue,
      isMixed: isMixed,
      onAlignmentSelected: onUpdate,
    ),
  );
}

class InspectorHorizontalTextAlignmentCapability
    extends InspectorCapability<TextHorizontalAlignment> {
  InspectorHorizontalTextAlignmentCapability({
    required super.fieldKey,
    required super.label,
    required TextHorizontalAlignment value,
    required ValueChanged<TextHorizontalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);
  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(TextHorizontalAlignment) onUpdate,
  ) => InspectorCapabilityFieldShell(
    label: label,
    child: TextHorizontalAlignmentSelector(
      activeAlignment: activeValue,
      isMixed: isMixed,
      onAlignmentSelected: onUpdate,
    ),
  );
}

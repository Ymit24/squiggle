import 'package:squiggle_flutter/models/style_value_serialization.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/text_alignment_selector.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';

class InspectorVerticalTextAlignmentField
    extends InspectorField<TextVerticalAlignment> {
  @override
  Object? encodeValue(TextVerticalAlignment value) => value.name;

  @override
  TextVerticalAlignment decodeValue(Object? raw) =>
      decodeStyleEnum(raw, TextVerticalAlignment.values);

  InspectorVerticalTextAlignmentField({
    required super.fieldKey,
    required super.label,
    required TextVerticalAlignment value,
    required ValueChanged<TextVerticalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(TextVerticalAlignment) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: TextVerticalAlignmentSelector(
      activeAlignment: activeValue,
      isMixed: isMixed,
      onAlignmentSelected: onUpdate,
    ),
  );
}

class InspectorHorizontalTextAlignmentField
    extends InspectorField<TextHorizontalAlignment> {
  @override
  Object? encodeValue(TextHorizontalAlignment value) => value.name;

  @override
  TextHorizontalAlignment decodeValue(Object? raw) =>
      decodeStyleEnum(raw, TextHorizontalAlignment.values);

  InspectorHorizontalTextAlignmentField({
    required super.fieldKey,
    required super.label,
    required TextHorizontalAlignment value,
    required ValueChanged<TextHorizontalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);
  @override
  InspectorFieldShell build(
    BuildContext context,
    void Function(TextHorizontalAlignment) onUpdate,
  ) => InspectorFieldShell(
    label: label,
    child: TextHorizontalAlignmentSelector(
      activeAlignment: activeValue,
      isMixed: isMixed,
      onAlignmentSelected: onUpdate,
    ),
  );
}

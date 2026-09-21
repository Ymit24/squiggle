import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/inspector_field_shell.dart';
import 'package:squiggle_flutter/models/feature.dart';

export 'inspector_color_field.dart';
export 'inspector_end_cap_field.dart';
export 'inspector_numeric_field.dart';
export 'inspector_text_alignment_field.dart';

abstract class InspectorField<T> {
  InspectorField({
    required this.fieldKey,
    required this.label,
    required this.values,
    required this.callbacks,
  });
  String fieldKey;
  String label;
  List<T> values;
  List<Function(T)> callbacks;
  T get activeValue => values.first;
  bool get isMixed => values.toSet().length > 1;

  static Map<String, InspectorField> byKeyForFeatures(List<Feature> features) {
    final inspectorFieldByKey = <String, InspectorField>{};
    for (final field in features.expand(
      (feature) => feature.kind.buildInspectorFields(),
    )) {
      final fieldKey = field.fieldKey;
      if (inspectorFieldByKey.containsKey(fieldKey)) {
        inspectorFieldByKey[fieldKey]!.merge(field);
      } else {
        inspectorFieldByKey[fieldKey] = field;
      }
    }
    return inspectorFieldByKey;
  }

  void merge(InspectorField<T> other) {
    values.addAll(other.values);
    callbacks.addAll(other.callbacks);
  }

  InspectorFieldShell build(BuildContext context, void Function(T) onUpdate);
  void apply(T value) {
    for (final callback in callbacks) {
      callback(value);
    }
  }
}

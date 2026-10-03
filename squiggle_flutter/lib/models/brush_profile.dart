import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/feature.dart';

/// A sparse set of appearance overrides. Missing fields leave defaults intact.
class BrushProfile {
  BrushProfile({
    required this.id,
    required this.name,
    Map<String, Object?>? values,
  }) : values = Map.of(values ?? {});

  static const scratchId = 'scratch';
  final String id;
  String name;

  /// Serialized field values; unsupported keys are retained across saves.
  final Map<String, Object?> values;
  bool get isScratch => id == scratchId;

  void applyTo(FeatureKind kind) {
    for (final field in kind.buildInspectorFields()) {
      if (values.containsKey(field.fieldKey)) {
        field.applySerialized(values[field.fieldKey]);
      }
    }
  }

  factory BrushProfile.fromDataModel(data.BrushProfile raw) =>
      BrushProfile(id: raw.id, name: raw.name, values: raw.values);

  data.BrushProfile toDataModel() => data.BrushProfile(
    id: id,
    name: name,
    values: Map<String, dynamic>.from(values),
  );
}

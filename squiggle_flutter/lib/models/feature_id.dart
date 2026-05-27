import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_id.freezed.dart';

/// Identifier for a document feature.
@freezed
abstract class FeatureId with _$FeatureId {
  const factory FeatureId({required int value}) = _FeatureId;

  factory FeatureId.newId(int id) => FeatureId(value: id);
}

const FeatureId noId = FeatureId(value: 0);

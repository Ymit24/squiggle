import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

part 'state.freezed.dart';

@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    required Document document,
    required List<FeatureId> selectedFeatures,
  }) = _EditorState;

  factory EditorState.empty(Document document) => EditorState(
    document: document,
    selectedFeatures: const [],
  );
}

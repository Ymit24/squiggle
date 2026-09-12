import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node_id.dart';

part 'state.freezed.dart';

@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    required Document document,
    required List<NodeId> selectedNodeIds,
  }) = _EditorState;

  factory EditorState.empty(Document document) =>
      EditorState(document: document, selectedNodeIds: const []);
}

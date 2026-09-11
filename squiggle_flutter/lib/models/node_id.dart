import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_id.freezed.dart';

/// Identifier for a document feature.
@freezed
abstract class NodeId with _$NodeId {
  const factory NodeId({required int value}) = _NodeId;

  factory NodeId.newId(int id) => NodeId(value: id);
}

const NodeId noId = NodeId(value: 0);

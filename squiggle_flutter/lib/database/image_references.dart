import 'package:data_models/data_models.dart' as data;

/// Hashes of every image referenced by [nodes], including inside groups.
///
/// Mirrors `FeatureKindImage.toDataModel`, which writes `type` and `imageId`.
Set<String> imageHashesIn(Iterable<data.Node> nodes) => nodes.fold(
  <String>{},
  (hashes, node) => switch (node) {
    data.Group(:final children) => hashes..addAll(imageHashesIn(children)),
    data.Feature(:final content) when content['type'] == 'image' =>
      hashes..add(content['imageId'] as String),
    _ => hashes,
  },
);

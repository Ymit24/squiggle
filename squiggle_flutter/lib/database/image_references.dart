import 'package:data_models/data_models.dart' as data;

/// Hashes of every image referenced by [nodes], including inside groups.
///
/// Mirrors `FeatureKindImage.toDataModel`, which writes `type` and `imageId`.
Set<String> imageHashesIn(Iterable<data.Node> nodes) {
  final hashes = <String>{};
  void visit(data.Node node) {
    if (node is data.Group) {
      node.children.forEach(visit);
    } else if (node is data.Feature && node.content['type'] == 'image') {
      hashes.add(node.content['imageId'] as String);
    }
  }

  nodes.forEach(visit);
  return hashes;
}

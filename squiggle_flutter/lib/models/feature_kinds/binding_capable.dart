import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Kinds whose ends can attach to other nodes and follow them.
mixin BindingCapable {
  Iterable<NodeBinding> get bindings;

  /// Stores the resolved bound positions as the feature's own geometry.
  void bakeBindings(Feature feature);

  /// Bakes, then drops the bindings whose target [keep] rejects.
  void unbind(Feature feature, {required bool Function(NodeId) keep});

  /// Gives [copy], a fresh copy of [source], [source]'s resolved geometry and
  /// bindings retargeted through [ids].
  void rebindCopy(Feature copy, Feature source, Map<NodeId, NodeId> ids);
}

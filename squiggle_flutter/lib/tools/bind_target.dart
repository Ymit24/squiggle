import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Screen distance outside a node's bounds that still snaps a line end to it.
const kBindSnapDistance = 8.0;

/// The top-level node a line end at [worldPoint] binds to, if any. A top-most
/// hit that [line] may not bind to, or that is [exclude], blocks binding
/// rather than reaching nodes beneath it.
Node? bindTargetAt(
  EditorContext context,
  Offset worldPoint, {
  Feature? line,
  NodeId? exclude,
}) {
  final slop = context.camera.screenLengthToWorldLength(kBindSnapDistance);
  for (final node in context.document.nodes.reversed) {
    if (identical(node, line) || !_snapsAt(node, worldPoint, slop)) continue;
    // Lines are thin, so pointing at one should still reach the shape below.
    if (node case Feature(kind: BindingCapable())) continue;
    if (node.id == exclude || !canBindTo(node, line: line)) return null;
    return node;
  }
  return null;
}

bool _snapsAt(Node node, Offset worldPoint, double slop) =>
    node.globalBounds().inflate(slop).contains(worldPoint);

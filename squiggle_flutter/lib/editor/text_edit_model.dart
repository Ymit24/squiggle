import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/models/node_id.dart';

sealed class TextEditSession {
  const TextEditSession({required this.initialContents, required this.layout});

  final String initialContents;

  /// Where the edited text is typeset, in document (root) world coordinates.
  final LabelLayout layout;
}

final class EditTextEditSession extends TextEditSession {
  const EditTextEditSession({
    required this.feature,
    required super.initialContents,
    required super.layout,
  });

  factory EditTextEditSession.forFeature(Feature feature) {
    final kind = feature.kind as LabelCapable;
    return EditTextEditSession(
      feature: feature,
      initialContents: kind.label,
      layout: kind
          .labelLayout(feature)
          .shifted(feature.parent?.globalOrigin ?? Offset.zero),
    );
  }

  final Feature feature;

  NodeId get featureId => feature.id;
}

final class CreateTextEditSession extends TextEditSession {
  const CreateTextEditSession({
    required this.worldOrigin,
    required super.initialContents,
    required super.layout,
  });

  final Offset worldOrigin;
}

/// Observable state of the active text edit session, if any.
class TextEditModel extends ChangeNotifier {
  TextEditSession? _session;

  /// Feature whose label is hidden on the canvas because the inline editor is
  /// drawing it instead.
  Feature? _labelHiddenFeature;

  /// What the text field currently contains. Kept here, not just in the
  /// field's controller, so anything that ends the edit can commit it.
  String draft = '';

  TextEditSession? get session => _session;

  /// Whether the text of the node [id] is being edited right now.
  bool isEditing(NodeId id) => switch (_session) {
    EditTextEditSession(:final featureId) => featureId == id,
    _ => false,
  };

  void begin(TextEditSession session) {
    _showHiddenLabel();
    _session = session;
    draft = session.initialContents;
    if (session case EditTextEditSession(:final feature)) {
      _labelHiddenFeature = feature..hideLabel = true;
    }
    notifyListeners();
  }

  void end() {
    if (_session == null) return;
    _showHiddenLabel();
    _session = null;
    notifyListeners();
  }

  void _showHiddenLabel() {
    _labelHiddenFeature?.hideLabel = false;
    _labelHiddenFeature = null;
  }
}

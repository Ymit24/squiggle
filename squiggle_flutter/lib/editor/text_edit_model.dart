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
    required this.featureId,
    required super.initialContents,
    required super.layout,
  });

  factory EditTextEditSession.forFeature(Feature feature) {
    final kind = feature.kind as LabelCapable;
    return EditTextEditSession(
      featureId: feature.id,
      initialContents: kind.label,
      layout: kind
          .labelLayout(feature)
          .shifted(feature.parent?.globalOrigin ?? Offset.zero),
    );
  }

  final NodeId featureId;
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

  TextEditSession? get session => _session;

  void begin(TextEditSession session) {
    _session = session;
    notifyListeners();
  }

  void end() {
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }
}

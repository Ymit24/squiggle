import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

sealed class TextEditSession {
  const TextEditSession({
    required this.initialContents,
    required this.canvasLocalBounds,
  });

  final String initialContents;
  final Rect canvasLocalBounds;
}

final class EditTextEditSession extends TextEditSession {
  const EditTextEditSession({
    required this.featureId,
    required super.initialContents,
    required super.canvasLocalBounds,
  });

  final FeatureId featureId;
}

final class CreateTextEditSession extends TextEditSession {
  const CreateTextEditSession({
    required this.worldOrigin,
    required super.initialContents,
    required super.canvasLocalBounds,
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

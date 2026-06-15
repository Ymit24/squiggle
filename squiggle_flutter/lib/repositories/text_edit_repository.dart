import 'dart:async';
import 'dart:ui';

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

class TextEditRepository {
  final _sessionController = StreamController<TextEditSession>.broadcast();

  Stream<TextEditSession> get editSessionStream => _sessionController.stream;

  void beginEdit(TextEditSession session) {
    _sessionController.add(session);
  }

  void dispose() {
    _sessionController.close();
  }
}

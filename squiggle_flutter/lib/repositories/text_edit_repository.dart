import 'dart:async';
import 'dart:ui';

import 'package:squiggle_flutter/models/feature_id.dart';

class TextEditSession {
  const TextEditSession({
    required this.featureId,
    required this.initialContents,
    required this.canvasLocalBounds,
  });

  final FeatureId featureId;
  final String initialContents;
  final Rect canvasLocalBounds;
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

import 'dart:ui';

import 'package:squiggle_flutter/models/feature_id.dart';

sealed class TextEditState {
  const TextEditState();
}

final class TextEditClosed extends TextEditState {
  const TextEditClosed();
}

final class TextEditOpen extends TextEditState {
  const TextEditOpen({
    required this.featureId,
    required this.initialContents,
    required this.canvasLocalBounds,
  });

  final FeatureId featureId;
  final String initialContents;
  final Rect canvasLocalBounds;
}

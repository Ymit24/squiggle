import 'dart:ui';

import 'package:squiggle_flutter/models/feature_id.dart';

sealed class TextEditState {
  const TextEditState();
}

final class TextEditClosed extends TextEditState {
  const TextEditClosed();
}

sealed class TextEditOpen extends TextEditState {
  const TextEditOpen({
    required this.initialContents,
    required this.canvasLocalBounds,
  });

  final String initialContents;
  final Rect canvasLocalBounds;
}

final class EditTextEditOpen extends TextEditOpen {
  const EditTextEditOpen({
    required this.featureId,
    required super.initialContents,
    required super.canvasLocalBounds,
  });

  final FeatureId featureId;
}

final class CreateTextEditOpen extends TextEditOpen {
  const CreateTextEditOpen({
    required this.worldOrigin,
    required super.initialContents,
    required super.canvasLocalBounds,
  });

  final Offset worldOrigin;
}

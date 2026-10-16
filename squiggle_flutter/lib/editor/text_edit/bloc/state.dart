import 'dart:ui';

import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/models/node_id.dart';

sealed class TextEditState {
  const TextEditState();
}

final class TextEditClosed extends TextEditState {
  const TextEditClosed();
}

sealed class TextEditOpen extends TextEditState {
  const TextEditOpen({required this.initialContents, required this.layout});

  final String initialContents;
  final LabelLayout layout;
}

final class EditTextEditOpen extends TextEditOpen {
  const EditTextEditOpen({
    required this.featureId,
    required super.initialContents,
    required super.layout,
  });

  final NodeId featureId;
}

final class CreateTextEditOpen extends TextEditOpen {
  const CreateTextEditOpen({
    required this.worldOrigin,
    required super.initialContents,
    required super.layout,
  });

  final Offset worldOrigin;
}

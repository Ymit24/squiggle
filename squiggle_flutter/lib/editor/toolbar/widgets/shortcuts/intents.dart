import 'package:flutter/widgets.dart';

class ActivateSelectToolIntent extends Intent {
  const ActivateSelectToolIntent();
}

class ActivateCreateRectToolIntent extends Intent {
  const ActivateCreateRectToolIntent();
}

class ActivateCreateCircleToolIntent extends Intent {
  const ActivateCreateCircleToolIntent();
}

class ActivateCreateLineToolIntent extends Intent {
  const ActivateCreateLineToolIntent();
}

class ActivateCreateTextToolIntent extends Intent {
  const ActivateCreateTextToolIntent();
}

class DeleteSelectedFeaturesIntent extends Intent {
  const DeleteSelectedFeaturesIntent();
}

class PasteImageIntent extends Intent {
  const PasteImageIntent();
}

class CopySelectedFeaturesIntent extends Intent {
  const CopySelectedFeaturesIntent();
}

class UndoDocumentIntent extends Intent {
  const UndoDocumentIntent();
}

class RedoDocumentIntent extends Intent {
  const RedoDocumentIntent();
}

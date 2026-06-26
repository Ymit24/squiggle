abstract class ToolbarEvent {
  const ToolbarEvent();
}

class ActivateSelectToolEvent extends ToolbarEvent {
  const ActivateSelectToolEvent();
}

class ActivateCreateRectToolEvent extends ToolbarEvent {
  const ActivateCreateRectToolEvent();
}

class ActivateCreateCircleToolEvent extends ToolbarEvent {
  const ActivateCreateCircleToolEvent();
}

class ActivateCreateLineToolEvent extends ToolbarEvent {
  const ActivateCreateLineToolEvent();
}

class ActivateCreateTextToolEvent extends ToolbarEvent {
  const ActivateCreateTextToolEvent();
}

class RequestWatchToolbarStateEvent extends ToolbarEvent {
  const RequestWatchToolbarStateEvent();
}

class UndoDocumentEvent extends ToolbarEvent {
  const UndoDocumentEvent();
}

class RedoDocumentEvent extends ToolbarEvent {
  const RedoDocumentEvent();
}

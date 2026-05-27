abstract class EditorEvent {
  const EditorEvent();
}

class RequestWatchEditorStateEvent extends EditorEvent {
  const RequestWatchEditorStateEvent();
}

class DeleteSelectedFeaturesEvent extends EditorEvent {
  const DeleteSelectedFeaturesEvent();
}

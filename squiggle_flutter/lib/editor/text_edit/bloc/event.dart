sealed class TextEditEvent {
  const TextEditEvent();
}

final class RequestWatchTextEditStateEvent extends TextEditEvent {
  const RequestWatchTextEditStateEvent();
}

final class TextEditSubmitted extends TextEditEvent {
  const TextEditSubmitted(this.contents, {this.selectCreated = true});

  final String contents;

  /// False when an outside click commits the edit: that click chooses the
  /// selection, so a newly created text must not steal it.
  final bool selectCreated;
}

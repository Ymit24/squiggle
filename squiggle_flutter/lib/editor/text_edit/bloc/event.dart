sealed class TextEditEvent {
  const TextEditEvent();
}

final class RequestWatchTextEditStateEvent extends TextEditEvent {
  const RequestWatchTextEditStateEvent();
}

final class TextEditSubmitted extends TextEditEvent {
  const TextEditSubmitted(this.contents);

  final String contents;
}

final class TextEditCancelled extends TextEditEvent {
  const TextEditCancelled();
}

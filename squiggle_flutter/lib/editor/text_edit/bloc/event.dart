sealed class TextEditEvent {
  const TextEditEvent();
}

final class RequestWatchTextEditStateEvent extends TextEditEvent {
  const RequestWatchTextEditStateEvent();
}

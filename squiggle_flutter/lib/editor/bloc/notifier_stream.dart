import 'dart:async';

import 'package:flutter/foundation.dart';

/// Broadcasts a signal each time [notifier] notifies its listeners.
///
/// The notifier listener is removed when the stream's last subscription is
/// cancelled.
Stream<void> notifierChangesStream(ChangeNotifier notifier) {
  late final StreamController<void> controller;
  void onChanged() => controller.add(null);
  controller = StreamController<void>.broadcast(
    onCancel: () {
      notifier.removeListener(onChanged);
      controller.close();
    },
  );
  notifier.addListener(onChanged);
  return controller.stream;
}

import 'package:flutter/gestures.dart';

/// Records which pointers a descendant widget has taken for itself, so an
/// ancestor `Listener` that sees every event can leave them alone.
///
/// A claim is made on pointer-down and held until [release], because a drag
/// that starts on a claimant keeps belonging to it after leaving its bounds.
class PointerClaims {
  final _claimed = <int>{};

  void claim(PointerEvent event) => _claimed.add(event.pointer);

  bool isClaimed(PointerEvent event) => _claimed.contains(event.pointer);

  void release(PointerEvent event) => _claimed.remove(event.pointer);
}

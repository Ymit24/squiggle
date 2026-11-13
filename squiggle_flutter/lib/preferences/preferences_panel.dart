import 'package:flutter/material.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_dialog.dart';

/// Shows the preferences dialog over whichever page is open, at most once.
class PreferencesPanel {
  PreferencesPanel({required this._navigatorKey});

  final GlobalKey<NavigatorState> _navigatorKey;
  Route<void>? _route;

  bool get isOpen => _route != null;

  void toggle() => isOpen ? close() : open();

  void open() {
    if (isOpen) return;
    final navigator = _navigatorKey.currentState!;
    final route = DialogRoute<void>(
      context: navigator.context,
      builder: (_) => const PreferencesDialog(),
    );
    _route = route;
    navigator.push(route).whenComplete(() {
      if (identical(_route, route)) _route = null;
    });
  }

  /// Closes the dialog unless something, such as a menu, is open above it.
  void close() {
    final route = _route;
    if (route == null || !route.isCurrent) return;
    route.navigator!.pop();
  }
}

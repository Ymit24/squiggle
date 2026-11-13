import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';

/// In-memory preferences; saves are dropped.
Preferences testPreferences([Map<String, String> values = const {}]) =>
    Preferences(save: (_, _) async {}, values: values);

/// Provides [preferences] (fresh defaults when omitted) to [child], as the
/// app shell does.
Widget withPreferences(Widget child, [Preferences? preferences]) =>
    ChangeNotifierProvider.value(
      value: preferences ?? testPreferences(),
      child: child,
    );

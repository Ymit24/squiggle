import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/preferences/preference.dart';

export 'package:squiggle_flutter/preferences/preference.dart';

/// App-wide preference values, read synchronously and saved on change.
///
/// Widgets read values with [PreferencesContext.watchPreference].
class Preferences extends ChangeNotifier {
  Preferences({required this._dao, Map<String, String> values = const {}})
    : _values = Map.of(values);

  final AppStateDao _dao;
  final Map<String, String> _values;

  static Future<Preferences> load(AppStateDao dao) async =>
      Preferences(dao: dao, values: await dao.preferences());

  T get<T>(Preference<T> preference) {
    final raw = _values[preference.key];
    if (raw == null) return preference.defaultValue;
    return preference.decode(raw) ?? preference.defaultValue;
  }

  /// Updates listeners immediately; the returned future completes once saved.
  Future<void> set<T>(Preference<T> preference, T value) async {
    final raw = preference.encode(value);
    if (_values[preference.key] == raw) return;
    _values[preference.key] = raw;
    notifyListeners();
    await _dao.setPreference(preference.key, raw);
  }
}

extension PreferencesContext on BuildContext {
  /// [preference]'s value, rebuilding only when that value changes.
  ///
  /// Reads the default where no [Preferences] is provided, so feature widgets
  /// still work outside the app shell, such as in isolated widget tests.
  T watchPreference<T>(Preference<T> preference) => select<Preferences?, T>(
    (preferences) => preferences?.get(preference) ?? preference.defaultValue,
  );
}

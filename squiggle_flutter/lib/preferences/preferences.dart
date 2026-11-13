import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/preferences/preference.dart';

export 'package:squiggle_flutter/preferences/preference.dart';

/// Persists one encoded preference value.
typedef SavePreference = Future<void> Function(String key, String value);

/// App-wide preference values, read synchronously and saved on change.
///
/// Widgets read values with [PreferencesContext.watchPreference].
class Preferences extends ChangeNotifier {
  Preferences({required this._save, Map<String, String> values = const {}})
    : _values = Map.of(values);

  final SavePreference _save;
  final Map<String, String> _values;

  /// The saved preferences, writing changes back to [dao].
  static Future<Preferences> load(AppStateDao dao) async =>
      Preferences(save: dao.setPreference, values: await dao.preferences());

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
    await _save(preference.key, raw);
  }
}

extension PreferencesContext on BuildContext {
  /// [preference]'s value, rebuilding only when that value changes.
  T watchPreference<T>(Preference<T> preference) =>
      select((Preferences preferences) => preferences.get(preference));
}

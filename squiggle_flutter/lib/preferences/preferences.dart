import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/preferences/preference.dart';

export 'package:squiggle_flutter/preferences/preference.dart';

/// App-wide preference values, read synchronously and saved on change.
///
/// Widgets should depend on a single value so they rebuild only when it
/// changes: `context.select((Preferences p) => p.get(somePreference))`.
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

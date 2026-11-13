import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/tables/app_state.dart';

part 'app_state_dao.g.dart';

@DriftAccessor(tables: [AppState])
class AppStateDao extends DatabaseAccessor<AppDatabase>
    with _$AppStateDaoMixin {
  AppStateDao(super.attachedDatabase);

  static const _activeDocumentIdKey = 'activeDocumentId';
  static const _preferencePrefix = 'preference.';

  Future<String?> activeDocumentId() => _get(_activeDocumentIdKey);

  Future<void> setActiveDocumentId(String id) => _set(_activeDocumentIdKey, id);

  /// Every stored preference, keyed without the storage prefix.
  Future<Map<String, String>> preferences() async {
    final rows = await (select(
      appState,
    )..where((t) => t.key.like('$_preferencePrefix%'))).get();
    return {
      for (final row in rows)
        row.key.substring(_preferencePrefix.length): row.value,
    };
  }

  Future<void> setPreference(String key, String value) =>
      _set('$_preferencePrefix$key', value);

  Future<String?> _get(String key) async {
    final row = await (select(
      appState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) => into(appState)
      .insertOnConflictUpdate(AppStateCompanion.insert(key: key, value: value));
}

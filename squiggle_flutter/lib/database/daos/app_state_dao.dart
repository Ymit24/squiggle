import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/tables/app_state.dart';

part 'app_state_dao.g.dart';

@DriftAccessor(tables: [AppState])
class AppStateDao extends DatabaseAccessor<AppDatabase>
    with _$AppStateDaoMixin {
  AppStateDao(super.attachedDatabase);

  static const _activeDocumentIdKey = 'activeDocumentId';

  Future<String?> activeDocumentId() => _get(_activeDocumentIdKey);

  Future<void> setActiveDocumentId(String id) => _set(_activeDocumentIdKey, id);

  Future<String?> _get(String key) async {
    final row = await (select(
      appState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) => into(appState)
      .insertOnConflictUpdate(AppStateCompanion.insert(key: key, value: value));
}

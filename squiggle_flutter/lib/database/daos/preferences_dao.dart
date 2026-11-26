import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/tables/preferences.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [Preferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.attachedDatabase);

  Future<String?> getValue(String key) async {
    final row = await (select(
      preferences,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchValue(String key) {
    return (select(
      preferences,
    )..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);
  }

  Future<void> setValue(String key, String value) => into(preferences)
      .insertOnConflictUpdate(PreferencesCompanion.insert(key: key, value: value));
}

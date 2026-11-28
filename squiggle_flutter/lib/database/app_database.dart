import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/database/daos/images_dao.dart';
import 'package:squiggle_flutter/database/daos/preferences_dao.dart';
import 'package:squiggle_flutter/database/tables/app_state.dart';
import 'package:squiggle_flutter/database/tables/documents.dart';
import 'package:squiggle_flutter/database/tables/images.dart';
import 'package:squiggle_flutter/database/tables/preferences.dart';

part 'app_database.g.dart';

/// The single SQLite database holding all documents and images.
@DriftDatabase(
  tables: [
    DocumentMetadatas,
    DocumentBodies,
    Images,
    ImageRefs,
    AppState,
    Preferences,
  ],
  daos: [DocumentsDao, ImagesDao, AppStateDao, PreferencesDao],
)
class AppDatabase extends _$AppDatabase {
  /// [clock] supplies timestamps for rows written by the DAOs.
  AppDatabase(super.executor, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final DateTime Function() clock;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedPreferences();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(preferences);
        await _seedPreferences();
      } else if (from < 3) {
        await preferencesDao.setValue('themeMode', 'system');
      }
    },
    // SQLite ignores foreign keys unless enabled per connection; without this
    // the cascading deletes below never run.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _seedPreferences() async {
    await preferencesDao.setValue('grid-lines-visible', 'true');
    await preferencesDao.setValue('themeMode', 'system');
  }
}

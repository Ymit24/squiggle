import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/database/daos/images_dao.dart';
import 'package:squiggle_flutter/database/tables/app_state.dart';
import 'package:squiggle_flutter/database/tables/documents.dart';
import 'package:squiggle_flutter/database/tables/images.dart';

part 'app_database.g.dart';

/// The single SQLite database holding all documents and images.
@DriftDatabase(
  tables: [DocumentMetadatas, DocumentBodies, Images, ImageRefs, AppState],
  daos: [DocumentsDao, ImagesDao, AppStateDao],
)
class AppDatabase extends _$AppDatabase {
  /// [clock] supplies timestamps for rows written by the DAOs.
  AppDatabase(super.executor, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  /// On-disk database in WAL mode, queried from a background isolate.
  AppDatabase.file(File file, {DateTime Function()? clock})
    : this(
        NativeDatabase.createInBackground(file, setup: _configureConnection),
        clock: clock,
      );

  final DateTime Function() clock;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // SQLite ignores foreign keys unless enabled per connection; without this
    // the cascading deletes below never run.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  static void _configureConnection(Database database) {
    database
      ..execute('PRAGMA journal_mode = WAL')
      ..execute('PRAGMA busy_timeout = 5000');
  }
}

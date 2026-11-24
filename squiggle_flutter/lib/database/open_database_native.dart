import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// Opens the on-disk SQLite database used by desktop builds.
Future<AppDatabase> openAppDatabase() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final directory = Directory('${supportDirectory.path}/Squiggle');
  await directory.create(recursive: true);
  final file = File('${directory.path}/squiggle.db');
  return openAppDatabaseFile(file);
}

/// Opens [file] as a native database. Used by the desktop opener and tests.
AppDatabase openAppDatabaseFile(File file) => AppDatabase(
  NativeDatabase.createInBackground(file, setup: _configureConnection),
);

void _configureConnection(Database database) {
  database
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA busy_timeout = 5000');
}

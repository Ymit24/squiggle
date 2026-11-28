import 'package:drift/wasm.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// Opens the browser database, persisted through Drift's browser storage.
Future<AppDatabase> openAppDatabase() async {
  final result = await WasmDatabase.open(
    databaseName: 'squiggle',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );
  return AppDatabase(result.resolvedExecutor);
}

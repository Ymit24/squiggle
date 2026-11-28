import 'package:drift/drift.dart';

/// User-facing key/value preferences persisted in SQLite.
@DataClassName('PreferenceRow')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

import 'package:drift/drift.dart';

/// Small key/value settings that belong to the app rather than a document.
@DataClassName('AppStateRow')
class AppState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

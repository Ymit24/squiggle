import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:squiggle_flutter/document_metadata_dao.dart';

part 'database.g.dart';

class DocumentMetadatas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class BrushProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
  TextColumn get values => text()();

  IntColumn get sortOrder => integer()();

  IntColumn get document => integer().references(DocumentMetadatas, #id)();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class Nodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get content => text()();

  IntColumn get nodeId => integer()();

  IntColumn get document => integer().references(DocumentMetadatas, #id)();

  IntColumn get sortOrder => integer()();

  IntColumn get parent => integer().references(Nodes, #id).nullable()();

  RealColumn get originX => real()();
  RealColumn get originY => real()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {document, id},
  ];
}

@DriftDatabase(
  tables: [DocumentMetadatas, BrushProfiles, Nodes],
  daos: [DocumentMetadataDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 0;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'squiggle_db',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

import 'package:drift/drift.dart';

/// Document metadata. Listing documents never reads [DocumentBodies].
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Cached library thumbnail; null until previews are generated.
  BlobColumn get previewPng => blob().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Document content, split from [Documents] so metadata queries stay cheap.
@DataClassName('DocumentBodyRow')
class DocumentBodies extends Table {
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();

  /// `dataModelFormatVersion` the [body] was written with.
  IntColumn get formatVersion => integer()();

  /// `data.Document.encode()`.
  TextColumn get body => text()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

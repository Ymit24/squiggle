import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/tables/documents.dart';

/// Image bytes keyed by the sha256 hex digest of the bytes.
@DataClassName('ImageRow')
class Images extends Table {
  TextColumn get hash => text()();
  BlobColumn get bytes => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {hash};
}

/// Which images each document references, rebuilt on every document save.
///
/// [imageHash] is a foreign key: an image must be stored before a document
/// that references it can be saved, and a referenced image cannot be deleted.
@DataClassName('ImageRefRow')
class ImageRefs extends Table {
  TextColumn get documentId =>
      text().references(DocumentMetadatas, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageHash => text().references(Images, #hash)();

  @override
  Set<Column<Object>> get primaryKey => {documentId, imageHash};
}

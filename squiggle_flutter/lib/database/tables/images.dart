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
/// [imageHash] deliberately has no foreign key: a document that references an
/// image missing from [Images] must still save.
@DataClassName('ImageRefRow')
class ImageRefs extends Table {
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {documentId, imageHash};
}

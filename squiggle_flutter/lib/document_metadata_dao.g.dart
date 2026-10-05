// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_metadata_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentMetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentMetadatasTable get documentMetadatas =>
      attachedDatabase.documentMetadatas;
  DocumentMetadataDaoManager get managers => DocumentMetadataDaoManager(this);
}

class DocumentMetadataDaoManager {
  final _$DocumentMetadataDaoMixin _db;
  DocumentMetadataDaoManager(this._db);
  $$DocumentMetadatasTableTableManager get documentMetadatas =>
      $$DocumentMetadatasTableTableManager(
        _db.attachedDatabase,
        _db.documentMetadatas,
      );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentMetadatasTable get documentMetadatas =>
      attachedDatabase.documentMetadatas;
  $DocumentBodiesTable get documentBodies => attachedDatabase.documentBodies;
  $ImagesTable get images => attachedDatabase.images;
  $ImageRefsTable get imageRefs => attachedDatabase.imageRefs;
  DocumentsDaoManager get managers => DocumentsDaoManager(this);
}

class DocumentsDaoManager {
  final _$DocumentsDaoMixin _db;
  DocumentsDaoManager(this._db);
  $$DocumentMetadatasTableTableManager get documentMetadatas =>
      $$DocumentMetadatasTableTableManager(
        _db.attachedDatabase,
        _db.documentMetadatas,
      );
  $$DocumentBodiesTableTableManager get documentBodies =>
      $$DocumentBodiesTableTableManager(
        _db.attachedDatabase,
        _db.documentBodies,
      );
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db.attachedDatabase, _db.images);
  $$ImageRefsTableTableManager get imageRefs =>
      $$ImageRefsTableTableManager(_db.attachedDatabase, _db.imageRefs);
}

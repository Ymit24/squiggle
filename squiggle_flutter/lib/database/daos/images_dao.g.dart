// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'images_dao.dart';

// ignore_for_file: type=lint
mixin _$ImagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ImagesTable get images => attachedDatabase.images;
  $DocumentMetadatasTable get documentMetadatas =>
      attachedDatabase.documentMetadatas;
  $ImageRefsTable get imageRefs => attachedDatabase.imageRefs;
  ImagesDaoManager get managers => ImagesDaoManager(this);
}

class ImagesDaoManager {
  final _$ImagesDaoMixin _db;
  ImagesDaoManager(this._db);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db.attachedDatabase, _db.images);
  $$DocumentMetadatasTableTableManager get documentMetadatas =>
      $$DocumentMetadatasTableTableManager(
        _db.attachedDatabase,
        _db.documentMetadatas,
      );
  $$ImageRefsTableTableManager get imageRefs =>
      $$ImageRefsTableTableManager(_db.attachedDatabase, _db.imageRefs);
}

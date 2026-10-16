// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentsTable get documents => attachedDatabase.documents;
  $DocumentBodiesTable get documentBodies => attachedDatabase.documentBodies;
  $ImageRefsTable get imageRefs => attachedDatabase.imageRefs;
  DocumentsDaoManager get managers => DocumentsDaoManager(this);
}

class DocumentsDaoManager {
  final _$DocumentsDaoMixin _db;
  DocumentsDaoManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db.attachedDatabase, _db.documents);
  $$DocumentBodiesTableTableManager get documentBodies =>
      $$DocumentBodiesTableTableManager(
        _db.attachedDatabase,
        _db.documentBodies,
      );
  $$ImageRefsTableTableManager get imageRefs =>
      $$ImageRefsTableTableManager(_db.attachedDatabase, _db.imageRefs);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_dao.dart';

// ignore_for_file: type=lint
mixin _$AppStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppStateTable get appState => attachedDatabase.appState;
  AppStateDaoManager get managers => AppStateDaoManager(this);
}

class AppStateDaoManager {
  final _$AppStateDaoMixin _db;
  AppStateDaoManager(this._db);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db.attachedDatabase, _db.appState);
}

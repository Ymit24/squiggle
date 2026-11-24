import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/open_database_native.dart';

void main() {
  group('AppDatabase', () {
    test('enforces foreign keys', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final row = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('file database uses WAL and persists across reopen', () async {
      final directory = await Directory.systemTemp.createTemp('squiggle_db_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/squiggle.sqlite');

      final first = openAppDatabaseFile(file);
      final mode = await first.customSelect('PRAGMA journal_mode').getSingle();
      expect(mode.read<String>('journal_mode'), 'wal');
      await first.appStateDao.setActiveDocumentId('doc-1');
      await first.close();

      final second = openAppDatabaseFile(file);
      addTearDown(second.close);
      expect(await second.appStateDao.activeDocumentId(), 'doc-1');
    });
  });
}

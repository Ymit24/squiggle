import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';

void main() {
  group('AppStateDao', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('active document id is null until set, then replaceable', () async {
      expect(await database.appStateDao.activeDocumentId(), isNull);

      await database.appStateDao.setActiveDocumentId('first');
      await database.appStateDao.setActiveDocumentId('second');

      expect(await database.appStateDao.activeDocumentId(), 'second');
    });

    test('preferences round-trip apart from other app state', () async {
      await database.appStateDao.setActiveDocumentId('doc');
      expect(await database.appStateDao.preferences(), isEmpty);

      await database.appStateDao.setPreference('canvas.grid', 'false');
      await database.appStateDao.setPreference('canvas.grid', 'true');
      await database.appStateDao.setPreference('theme', 'light');

      expect(await database.appStateDao.preferences(), {
        'canvas.grid': 'true',
        'theme': 'light',
      });
      expect(await database.appStateDao.activeDocumentId(), 'doc');
    });
  });
}

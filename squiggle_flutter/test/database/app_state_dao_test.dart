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
  });
}

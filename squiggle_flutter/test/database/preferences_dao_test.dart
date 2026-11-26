import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';

void main() {
  group('PreferencesDao', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('getValue returns null until set, then overwrites on conflict', () async {
      expect(await database.preferencesDao.getValue('custom-key'), isNull);

      await database.preferencesDao.setValue('custom-key', 'one');
      expect(await database.preferencesDao.getValue('custom-key'), 'one');

      await database.preferencesDao.setValue('custom-key', 'two');
      expect(await database.preferencesDao.getValue('custom-key'), 'two');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';

import '../support/test_database.dart';

void main() {
  group('DocumentListNotifier', () {
    late AppDatabase database;
    late DocumentListNotifier list;

    setUp(() {
      database = createTestDatabase();
      list = DocumentListNotifier(documentsDao: database.documentsDao);
    });

    tearDown(() async {
      list.dispose();
      await database.close();
    });

    test('is empty until refreshed', () async {
      await database.documentsDao.create(name: 'A');
      expect(list.documents, isEmpty);

      await list.refresh();
      expect(list.documents.map((doc) => doc.name), ['A']);
    });

    test('notifies listeners on refresh', () async {
      var notifications = 0;
      list.addListener(() => notifications++);

      await list.refresh();

      expect(notifications, 1);
    });

    test('exposes an unmodifiable list', () async {
      await list.refresh();
      expect(() => list.documents.clear(), throwsUnsupportedError);
    });

    test('nextUntitledName skips names already in use', () async {
      expect(list.nextUntitledName(), 'Untitled');

      await database.documentsDao.create(name: 'Untitled');
      await list.refresh();
      expect(list.nextUntitledName(), 'Untitled 2');

      await database.documentsDao.create(name: 'Untitled 2');
      await list.refresh();
      expect(list.nextUntitledName(), 'Untitled 3');
    });
  });
}

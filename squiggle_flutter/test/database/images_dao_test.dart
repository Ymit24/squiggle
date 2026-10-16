import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';

void main() {
  group('ImagesDao', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('stores bytes by hash and returns null for unknown hashes', () async {
      await database.imagesDao.insertIfAbsent('a', Uint8List.fromList([1, 2]));

      expect(await database.imagesDao.bytes('a'), [1, 2]);
      expect(await database.imagesDao.bytes('missing'), isNull);
    });

    test('keeps the original bytes when a hash is inserted again', () async {
      await database.imagesDao.insertIfAbsent('a', Uint8List.fromList([1]));
      await database.imagesDao.insertIfAbsent('a', Uint8List.fromList([9]));

      expect(await database.imagesDao.bytes('a'), [1]);
      expect(await database.select(database.images).get(), hasLength(1));
    });

    test('deleteUnreferenced removes only unreferenced images', () async {
      final document = await database.documentsDao.create(name: 'Doc');
      await database.imagesDao.insertIfAbsent('kept', Uint8List.fromList([1]));
      await database.imagesDao.insertIfAbsent('gone', Uint8List.fromList([2]));
      await database
          .into(database.imageRefs)
          .insert(
            ImageRefsCompanion.insert(
              documentId: document.id,
              imageHash: 'kept',
            ),
          );

      expect(await database.imagesDao.deleteUnreferenced(), 1);

      expect(await database.imagesDao.bytes('kept'), isNotNull);
      expect(await database.imagesDao.bytes('gone'), isNull);
    });
  });
}

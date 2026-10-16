import 'package:data_models/data_models.dart' as data;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';

data.Feature _image(int id, String hash) => data.Feature(
  id: id,
  originX: 1,
  originY: 2,
  width: 10,
  height: 10,
  content: {'type': 'image', 'imageId': hash},
);

void main() {
  group('DocumentsDao', () {
    late DateTime now;
    late AppDatabase database;

    DocumentsDao dao() => database.documentsDao;

    setUp(() {
      now = DateTime.utc(2026, 1, 1);
      database = AppDatabase(NativeDatabase.memory(), clock: () => now);
    });
    tearDown(() => database.close());

    test('creates an empty document that can be loaded', () async {
      final info = await dao().create(name: 'First');

      expect(info.name, 'First');
      final loaded = await dao().load(info.id);
      expect(loaded!.name, 'First');
      expect(loaded.nodes, isEmpty);
    });

    test('load returns null for an unknown id', () async {
      expect(await dao().load('missing'), isNull);
    });

    test('lists documents most recently updated first', () async {
      final first = await dao().create(name: 'First');
      now = now.add(const Duration(minutes: 1));
      final second = await dao().create(name: 'Second');
      now = now.add(const Duration(minutes: 1));
      await dao().save(first.id, data.Document(name: 'First'));

      final listed = await dao().list();

      expect(listed.map((info) => info.id), [first.id, second.id]);
    });

    test('save round-trips nodes and the brush session', () async {
      final info = await dao().create(name: 'Doc');
      final document = data.Document(
        name: 'Doc',
        nodes: [_image(1, 'a')],
        session: const data.DocumentSession(
          brushes: [
            data.BrushProfile(id: 'b1', name: 'Ink', values: {'w': 3.0}),
          ],
          activeBrushId: 'b1',
        ),
      );

      await dao().save(info.id, document);
      final loaded = await dao().load(info.id);

      expect(loaded!.nodes, document.nodes);
      expect(loaded.session.activeBrushId, 'b1');
      expect(loaded.session.brushes.single.values, {'w': 3.0});
    });

    test('the name column wins over the name inside the body', () async {
      final info = await dao().create(name: 'Original');
      await dao().rename(info.id, 'Renamed');

      await dao().save(info.id, data.Document(name: 'Stale'));

      expect((await dao().load(info.id))!.name, 'Renamed');
      expect((await dao().list()).single.name, 'Renamed');
    });

    test('save and rename bump updatedAt', () async {
      final info = await dao().create(name: 'Doc');

      now = now.add(const Duration(hours: 1));
      await dao().save(info.id, data.Document());
      expect((await dao().list()).single.updatedAt.isAtSameMomentAs(now), true);

      now = now.add(const Duration(hours: 1));
      await dao().rename(info.id, 'Other');
      expect((await dao().list()).single.updatedAt.isAtSameMomentAs(now), true);
    });

    test('save rebuilds image references', () async {
      final info = await dao().create(name: 'Doc');

      await dao().save(
        info.id,
        data.Document(nodes: [_image(1, 'a'), _image(2, 'b')]),
      );
      await dao().save(info.id, data.Document(nodes: [_image(1, 'b')]));

      final refs = await database.select(database.imageRefs).get();
      expect(refs.map((ref) => ref.imageHash), ['b']);
    });

    test('save for a deleted document is a no-op', () async {
      final info = await dao().create(name: 'Doc');
      await dao().remove(info.id);

      await dao().save(info.id, data.Document(nodes: [_image(1, 'a')]));

      expect(await database.select(database.documentBodies).get(), isEmpty);
      expect(await database.select(database.imageRefs).get(), isEmpty);
    });

    test('remove cascades to the body and image references', () async {
      final kept = await dao().create(name: 'Kept');
      final removed = await dao().create(name: 'Removed');
      await dao().save(removed.id, data.Document(nodes: [_image(1, 'a')]));
      await dao().save(kept.id, data.Document(nodes: [_image(1, 'a')]));

      await dao().remove(removed.id);

      expect((await dao().list()).map((info) => info.id), [kept.id]);
      final bodies = await database.select(database.documentBodies).get();
      expect(bodies.map((body) => body.documentId), [kept.id]);
      final refs = await database.select(database.imageRefs).get();
      expect(refs.map((ref) => ref.documentId), [kept.id]);
    });

    test('load throws on an undecodable body and keeps the row', () async {
      final info = await dao().create(name: 'Doc');
      await (database.update(database.documentBodies)
            ..where((t) => t.documentId.equals(info.id)))
          .write(const DocumentBodiesCompanion(body: Value('{"version":1}')));

      await expectLater(dao().load(info.id), throwsFormatException);

      expect(await dao().list(), hasLength(1));
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/migration/legacy_importer.dart';

import '../support/test_database.dart';

data.Feature _image(int id, String imageId) => data.Feature(
  id: id,
  originX: 1,
  originY: 2,
  width: 10,
  height: 10,
  content: {'type': 'image', 'imageId': imageId, 'strokeWidth': 2.0},
);

data.Feature _rect(int id) => data.Feature(
  id: id,
  originX: id.toDouble(),
  originY: 0,
  width: 10,
  height: 10,
  content: {'type': 'rectangle'},
);

void main() {
  late Directory root;
  late AppDatabase database;
  late LegacyImporter importer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('squiggle_legacy_');
    await Directory('${root.path}/documents').create();
    await Directory('${root.path}/images').create();
    database = createTestDatabase();
    importer = LegacyImporter(legacyRoot: root, database: database);
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  Future<void> writeDocument(
    String id,
    data.Document document, {
    DateTime? modified,
  }) async {
    final file = File('${root.path}/documents/$id.json');
    await file.writeAsString(document.encode());
    if (modified != null) await file.setLastModified(modified);
  }

  Future<String> writeImage(String name, List<int> bytes) async {
    await File('${root.path}/images/$name').writeAsBytes(bytes);
    return sha256.convert(bytes).toString();
  }

  test('reports whether there is anything to import', () async {
    expect(await importer.hasLegacyDocuments(), isFalse);
    await writeDocument('doc_1', const data.Document(name: 'One'));
    expect(await importer.hasLegacyDocuments(), isTrue);
  });

  test('imports documents with fresh ids, names and file times', () async {
    final modified = DateTime.utc(2024, 3, 4, 5, 6, 7);
    await writeDocument(
      'doc_1_abc',
      const data.Document(name: 'One'),
      modified: modified,
    );

    final report = await importer.run();

    expect(report.documentsImported, 1);
    final documents = await database.documentsDao.list();
    expect(documents.single.name, 'One');
    expect(documents.single.id, isNot('doc_1_abc'));
    expect(documents.single.updatedAt.toUtc(), modified);
  });

  test('rewrites old image ids to hashes, including inside groups', () async {
    final hash = await writeImage('img_123_ab.png', [1, 2, 3]);
    final sameHash = await writeImage(hash, [1, 2, 3]);
    expect(sameHash, hash);
    await writeDocument(
      'doc_1',
      data.Document(
        nodes: [
          _image(1, 'img_123_ab.png'),
          data.Group(
            id: 2,
            originX: 0,
            originY: 0,
            children: [_image(3, hash)],
          ),
        ],
      ),
    );

    final report = await importer.run();

    expect(report.problems, isEmpty);
    expect(report.images, 2);
    expect(await database.select(database.images).get(), hasLength(1));
    final id = (await database.documentsDao.list()).single.id;
    final loaded = (await database.documentsDao.load(id))!;
    final first = loaded.nodes.first as data.Feature;
    final group = loaded.nodes.last as data.Group;
    expect(first.content['imageId'], hash);
    expect((group.children.single as data.Feature).content['imageId'], hash);
    expect(await database.select(database.imageRefs).get(), hasLength(1));
  });

  test('leaves out image nodes whose file is missing', () async {
    await writeDocument(
      'doc_1',
      data.Document(nodes: [_rect(1), _image(2, 'img_gone.png')]),
    );

    final report = await importer.run();

    expect(report.imageNodesDropped, 1);
    final id = (await database.documentsDao.list()).single.id;
    expect((await database.documentsDao.load(id))!.nodes, hasLength(1));
  });

  test('skips unreadable and old-version documents and keeps going', () async {
    await File('${root.path}/documents/bad.json').writeAsString('not json');
    await File('${root.path}/documents/old.json')
        .writeAsString(jsonEncode({'version': 1, 'name': 'Old', 'nodes': []}));
    await writeDocument('good', const data.Document(name: 'Good'));

    final report = await importer.run();

    expect(report.documentsImported, 1);
    expect(report.problems, hasLength(2));
    expect((await database.documentsDao.list()).single.name, 'Good');
  });

  test('maps the old active document id to the new one', () async {
    await writeDocument('doc_a', const data.Document(name: 'A'));
    await writeDocument('doc_b', const data.Document(name: 'B'));
    await File('${root.path}/active_document.txt').writeAsString('doc_b\n');

    await importer.run();

    final active = await database.appStateDao.activeDocumentId();
    final documents = await database.documentsDao.list();
    expect(documents.firstWhere((doc) => doc.id == active).name, 'B');
  });

  test('a second run does not import documents again', () async {
    await writeDocument('doc_a', const data.Document(name: 'A'));

    await importer.run();
    final second = await importer.run();

    expect(second.documentsImported, 0);
    expect(second.documentsAlreadyImported, 1);
    expect(await database.documentsDao.list(), hasLength(1));
  });

  test('imports a large document into an on-disk database quickly', () async {
    final big = data.Document(
      name: 'Big',
      nodes: [for (var i = 0; i < 20000; i++) _rect(i)],
    );
    await writeDocument('big', big);
    final bytes = Uint8List.fromList(List.generate(2 << 20, (i) => i % 251));
    await writeImage('img_big.png', bytes);

    final diskDatabase = AppDatabase.file(File('${root.path}/squiggle.db'));
    addTearDown(diskDatabase.close);
    final stopwatch = Stopwatch()..start();
    final report = await LegacyImporter(
      legacyRoot: root,
      database: diskDatabase,
    ).run();
    stopwatch.stop();

    expect(report.problems, isEmpty);
    // ignore: avoid_print
    print(
      'large import: ${stopwatch.elapsedMilliseconds} ms '
      '(${big.encode().length} bytes of JSON)',
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/repositories/image_store.dart';

void main() {
  late Directory directory;
  late ImageStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('squiggle_store_test');
    store = ImageStore(directory: directory);
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'put returns the sha256 hex of the bytes and get returns them',
    () async {
      final id = await store.put(Uint8List.fromList([1, 2, 3]));

      expect(
        id,
        '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
      );
      expect(await store.get(id), [1, 2, 3]);
    },
  );

  test('putting the same bytes twice stores one file', () async {
    final first = await store.put(Uint8List.fromList([7, 7]));
    final second = await store.put(Uint8List.fromList([7, 7]));

    expect(second, first);
    expect(await directory.list().length, 1);
  });

  test('get returns null for an unknown id', () async {
    expect(await store.get('missing'), isNull);
  });

  test('loads images stored under their old file names', () async {
    await File('${directory.path}/img_1_abc123.png').writeAsBytes([9, 9]);

    expect(await store.get('img_1_abc123.png'), [9, 9]);
  });

  test('creates the directory on first use', () async {
    final nested = Directory('${directory.path}/nested/images');

    final id = await ImageStore(directory: nested).put(Uint8List.fromList([4]));

    expect(await nested.exists(), isTrue);
    expect(await File('${nested.path}/$id').exists(), isTrue);
  });
}

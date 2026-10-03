import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sourceDirectory;
  late Directory targetDirectory;
  late ImageRepository source;
  late ImageRepository target;

  setUp(() async {
    sourceDirectory = await Directory.systemTemp.createTemp('clipboard_source');
    targetDirectory = await Directory.systemTemp.createTemp('clipboard_target');
    source = ImageRepository(imagesDirectory: sourceDirectory);
    target = ImageRepository(imagesDirectory: targetDirectory);
    await source.initialize();
    await target.initialize();
  });
  tearDown(() async {
    source.dispose();
    target.dispose();
    await sourceDirectory.delete(recursive: true);
    await targetDirectory.delete(recursive: true);
  });

  test(
    'nested groups transfer a shared PNG once with fresh node IDs',
    () async {
      final png = await _testPng();
      final imported = (await source.importPngBytes(png))!;
      final image = Feature(
        id: NodeId.newId(12),
        origin: const Offset(5, 7),
        size: const Size(8, 6),
        kind: FeatureKindImage(imported.imageId, strokeWidth: 3),
      );
      final nested = Group(
        id: NodeId.newId(11),
        origin: const Offset(20, 30),
        children: [image],
      );
      final group = Group(
        id: NodeId.newId(10),
        origin: const Offset(100, 200),
        children: [
          nested,
          image.copyWith(id: NodeId.newId(13)),
        ],
      );
      final before = group.toDataModel().toJson();
      final payload = await encodeNodesForClipboard([group], source);
      expect((jsonDecode(payload) as Map)['images'], hasLength(1));
      final decoded = (await decodeNodesFromClipboard(payload, target))!;
      final decodedGroup = decoded.single as Group;
      final decodedNested = decodedGroup.children.first as Group;
      final firstImage = decodedNested.children.single as Feature;
      final secondImage = decodedGroup.children.last as Feature;
      final firstKind = firstImage.kind as FeatureKindImage;
      final secondKind = secondImage.kind as FeatureKindImage;

      expect([
        decodedGroup.id,
        decodedNested.id,
        firstImage.id,
        secondImage.id,
      ], everyElement(noId));
      expect(decodedGroup.origin, group.origin);
      expect(decodedNested.origin, nested.origin);
      expect(firstImage.origin, image.origin);
      expect(firstImage.size, image.size);
      expect(firstKind.strokeWidth, 3);
      expect(firstKind.imageId, isNot(imported.imageId));
      expect(secondKind.imageId, firstKind.imageId);
      expect(await target.readPngBytes(firstKind.imageId), orderedEquals(png));
      expect(await targetDirectory.list().length, 1);
      expect(group.toDataModel().toJson(), before);
    },
  );

  test('text round-trips without image attachments', () async {
    final feature = Feature(
      id: NodeId.newId(42),
      origin: const Offset(10, 20),
      size: const Size(120, 80),
      kind: FeatureKindText('Hello\nworld'),
    );
    final payload = await encodeNodesForClipboard([feature], source);
    final decoded = (await decodeNodesFromClipboard(payload, target))!;
    expect(
      decoded.single.toDataModel().toJson(),
      feature.copyWith(id: noId).toDataModel().toJson(),
    );
    expect(await targetDirectory.list().isEmpty, isTrue);
  });

  test('rejects malformed nodes and missing or invalid images', () async {
    final image = Feature(
      origin: Offset.zero,
      size: const Size(8, 6),
      kind: FeatureKindImage('missing.png'),
    );
    final nodes = [image.toDataModel().toJson()];
    final payloads = [
      'not json',
      jsonEncode({
        'nodes': [
          {'type': 'unknown'},
        ],
        'images': {},
      }),
      jsonEncode({'nodes': nodes, 'images': {}}),
      jsonEncode({
        'nodes': nodes,
        'images': {'missing.png': '%%%'},
      }),
      jsonEncode({
        'nodes': nodes,
        'images': {
          'missing.png': base64Encode([1, 2, 3]),
        },
      }),
    ];
    for (final payload in payloads) {
      expect(await decodeNodesFromClipboard(payload, target), isNull);
    }
    expect(await targetDirectory.list().isEmpty, isTrue);
    await expectLater(
      encodeNodesForClipboard([image], source),
      throwsStateError,
    );
  });
}

Future<Uint8List> _testPng() async {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 8, 6),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 6);
  final data = await image.toByteData(format: ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

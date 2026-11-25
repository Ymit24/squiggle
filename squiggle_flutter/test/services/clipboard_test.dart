import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/clipboard.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase sourceDatabase;
  late AppDatabase targetDatabase;
  late ImageRepository source;
  late ImageRepository target;

  setUp(() async {
    sourceDatabase = createTestDatabase();
    targetDatabase = createTestDatabase();
    source = ImageRepository(images: sourceDatabase.imagesDao);
    target = ImageRepository(images: targetDatabase.imagesDao);
  });
  tearDown(() async {
    source.dispose();
    target.dispose();
    await sourceDatabase.close();
    await targetDatabase.close();
  });

  test('nested groups transfer a shared PNG once keeping payload node IDs and the same hash id', () async {
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

    // Pasting inserts copies with fresh ids; decoding keeps the payload's.
    expect([
      decodedGroup.id,
      decodedNested.id,
      firstImage.id,
      secondImage.id,
    ], [10, 11, 12, 13].map(NodeId.newId));
    expect(decodedGroup.origin, group.origin);
    expect(decodedNested.origin, nested.origin);
    expect(firstImage.origin, image.origin);
    expect(firstImage.size, image.size);
    expect(firstKind.strokeWidth, 3);
    expect(firstKind.imageId, imported.imageId);
    expect(secondKind.imageId, firstKind.imageId);
    expect(await target.readPngBytes(firstKind.imageId), orderedEquals(png));
    expect(
      await targetDatabase.select(targetDatabase.images).get(),
      hasLength(1),
    );
    expect(group.toDataModel().toJson(), before);
  });

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
      feature.toDataModel().toJson(),
    );
    expect(await targetDatabase.select(targetDatabase.images).get(), isEmpty);
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
    expect(await targetDatabase.select(targetDatabase.images).get(), isEmpty);
    await expectLater(
      encodeNodesForClipboard([image], source),
      throwsStateError,
    );
  });

  group('bindings', () {
    late Document document;
    late Feature circle;
    late Feature rect;
    late Feature line;

    setUp(() {
      document = Document();
      circle = document.insert(
        Feature(
          origin: Offset.zero,
          size: const Size(100, 100),
          kind: FeatureKindCircle(),
        ),
      );
      rect = document.insert(
        Feature(
          origin: const Offset(300, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      );
      line = document.insert(
        Feature(
          origin: const Offset(50, 50),
          size: Size.zero,
          kind: FeatureKindPolyline(
            const [Offset.zero, Offset(300, 0)],
            startBinding: NodeBinding(circle.id),
            endBinding: NodeBinding(rect.id),
          ),
        ),
      );
    });

    /// Copies [nodes], then pastes them into [document] the way paste does.
    Future<List<Node>> roundTrip(List<Node> nodes) async {
      final payload = await encodeNodesForClipboard(nodes, source);
      final decoded = (await decodeNodesFromClipboard(payload, target))!;
      late List<Node> pasted;
      History(document: document).run('Paste', (transaction) {
        pasted = duplicateNodes(
          nodes: decoded,
          transaction: transaction,
          selection: SelectionModel(),
        );
      });
      return pasted;
    }

    FeatureKindPolyline kindOf(Node node) =>
        (node as Feature).kind as FeatureKindPolyline;

    test('a pasted line binds to the pasted shapes', () async {
      final [newCircle, newRect, newLine] = await roundTrip([
        circle,
        rect,
        line,
      ]);
      expect(kindOf(newLine).startBinding?.targetId, newCircle.id);
      expect(kindOf(newLine).endBinding?.targetId, newRect.id);
      expect(newCircle.id, isNot(circle.id));
    });

    test(
      'a line pasted alone keeps its shape and drops its bindings',
      () async {
        final [newLine] = await roundTrip([line]);
        final kind = kindOf(newLine);
        expect(kind.bindings, isEmpty);
        expect(kind.resolvedPoints(newLine as Feature), [
          const Offset(100, 50),
          const Offset(300, 50),
        ]);
      },
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

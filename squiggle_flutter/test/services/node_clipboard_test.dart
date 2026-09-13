import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('repositionNodesToCenter', () {
    test('centers a single feature on the target', () {
      final feature = Feature(
        origin: const Offset(100, 50),
        size: const Size(200, 100),
        kind: FeatureKindRectangle(),
      );

      final repositioned = repositionNodesToCenter([
        feature,
      ], const Offset(500, 400));

      expect(repositioned, hasLength(1));
      expect(repositioned.first.localBounds().center, const Offset(500, 400));
    });

    test('preserves relative offsets for multiple features', () {
      final first = Feature(
        origin: const Offset(0, 0),
        size: const Size(100, 100),
        kind: FeatureKindRectangle(),
      );
      final second = Feature(
        origin: const Offset(120, 40),
        size: const Size(50, 50),
        kind: FeatureKindCircle(),
      );

      final repositioned = repositionNodesToCenter([
        first,
        second,
      ], const Offset(300, 300));

      expect(
        Node.localBoundsOfNodes(repositioned).center,
        const Offset(300, 300),
      );
      expect(
        repositioned[1].origin - repositioned[0].origin,
        second.origin - first.origin,
      );
    });
  });

  test(
    'clipboard round-trips group trees, fresh IDs, and image bytes',
    () async {
      final sourceDir = await Directory.systemTemp.createTemp(
        'clipboard_source',
      );
      final targetDir = await Directory.systemTemp.createTemp(
        'clipboard_target',
      );
      final source = ImageRepository(imagesDirectory: sourceDir);
      final target = ImageRepository(imagesDirectory: targetDir);
      await source.initialize();
      await target.initialize();
      addTearDown(() async {
        source.dispose();
        target.dispose();
        await sourceDir.delete(recursive: true);
        await targetDir.delete(recursive: true);
      });

      final imported = await source.importPngBytes(await _testPng());
      final group = Group(
        id: NodeId.newId(10),
        origin: const Offset(100, 200),
        children: [
          Feature(
            id: NodeId.newId(11),
            origin: Offset.zero,
            size: const Size(8, 6),
            kind: FeatureKindImage(imported!.imageId),
          ),
        ],
      );

      final payload = await encodeNodesForClipboard([group], source);
      final decoded = await decodeNodesFromClipboard(payload, target);

      final decodedGroup = decoded!.single as Group;
      final decodedImage = decodedGroup.children.single as Feature;
      final decodedKind = decodedImage.kind as FeatureKindImage;
      expect(decodedGroup.id, noId);
      expect(decodedImage.id, noId);
      expect(decodedGroup.origin, group.origin);
      expect(decodedKind.imageId, isNot(imported.imageId));
      expect(await target.readPngBytes(decodedKind.imageId), isNotEmpty);
    },
  );
}

Future<Uint8List> _testPng() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 8, 6),
    Paint()..color = const Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(8, 6);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

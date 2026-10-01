import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';
import 'package:squiggle_flutter/services/copy_nodes.dart';

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
    'clipboard retains tree IDs for remapping and round-trips image bytes',
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
      expect(decodedGroup.id, group.id);
      expect(decodedImage.id, group.children.single.id);
      expect(decodedGroup.origin, group.origin);
      expect(decodedKind.imageId, isNot(imported.imageId));
      expect(await target.readPngBytes(decodedKind.imageId), isNotEmpty);
    },
  );

  group('clipboard bindings', () {
    late ImageRepository images;
    setUp(() async {
      final directory = await Directory.systemTemp.createTemp(
        'clipboard_binds',
      );
      images = ImageRepository(imagesDirectory: directory);
      await images.initialize();
      addTearDown(() async {
        images.dispose();
        await directory.delete(recursive: true);
      });
    });

    test(
      'line-only transfer detaches before colliding destination IDs exist',
      () async {
        final target = Feature(
          origin: const Offset(100, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        );
        final line = Feature(
          origin: Offset.zero,
          size: Size.zero,
          kind: FeatureKindPolyline([Offset.zero, const Offset(50, 50)]),
        );
        final source = Document()..addNodes([target, line]);
        final kind = line.kind as FeatureKindPolyline;
        kind.startBinding = RadialBinding(target.id, 0);
        kind.endBinding = RadialBinding(target.id, 0);
        target.origin += const Offset(80, 40);
        final points = kind.resolvedGlobalPoints(line);
        final before = source.toDataModel();

        final payload = await encodeNodesForClipboard([line], images);
        expect(source.toDataModel().nodes, before.nodes);
        // Changes after copying must not change the exported geometry.
        target.origin += const Offset(100, 0);
        final decoded = (await decodeNodesFromClipboard(payload, images))!;
        final unrelated = Feature(
          id: target.id,
          origin: const Offset(1000, 1000),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        );
        final destination = Document()..addNode(unrelated);
        final copies = copyNodes(
          decoded,
          allocateId: (_) => destination.generateId(),
        );
        destination.addNodes(copies);

        final copy = copies.single as Feature;
        final copiedKind = copy.kind as FeatureKindPolyline;
        expect(copiedKind.bindings, isEmpty);
        expect(copiedKind.resolvedGlobalPoints(copy), points);
        unrelated.origin += const Offset(100, 0);
        expect(copiedKind.resolvedGlobalPoints(copy), points);
      },
    );

    test(
      'group transfer preserves internal connections through paste and history',
      () async {
        final target = Feature(
          origin: const Offset(100, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        );
        final line = Feature(
          origin: Offset.zero,
          size: Size.zero,
          kind: FeatureKindPolyline([Offset.zero, const Offset(50, 50)]),
        );
        final group = Group(
          origin: const Offset(200, 100),
          children: [line, target],
        );
        Document().addNode(group);
        (line.kind as FeatureKindPolyline).endBinding = RadialBinding(
          target.id,
          0,
        );
        target.origin += const Offset(50, 50);
        final payload = await encodeNodesForClipboard([group], images);
        final decoded = (await decodeNodesFromClipboard(payload, images))!;
        final context = EditorContext(document: Document());
        // Force every pasted ID to differ from the payload IDs.
        context.document.addNode(
          Feature(
            id: NodeId.newId(100),
            origin: const Offset(1000, 1000),
            size: const Size(100, 100),
            kind: FeatureKindRectangle(),
          ),
        );
        final before = context.document.toDataModel();
        final copies = copyNodes(
          decoded,
          allocateId: (_) => context.document.generateId(),
        );
        final positioned = repositionNodesToCenter(
          copies,
          const Offset(500, 500),
        );
        context.history.run('Paste', (edit) {
          for (final node in positioned) {
            edit.add(node);
          }
        });

        final pasted = positioned.single as Group;
        final copiedLine = pasted.children.first as Feature;
        final copiedTarget = pasted.children.last as Feature;
        final kind = copiedLine.kind as FeatureKindPolyline;
        expect(pasted.id, isNot(group.id));
        expect(kind.endBinding!.targetId, copiedTarget.id);
        expect(pasted.globalBounds().center, const Offset(500, 500));
        final after = context.document.toDataModel();
        context.undo();
        expect(context.document.toDataModel().nodes, before.nodes);
        context.redo();
        expect(context.document.toDataModel().nodes, after.nodes);
        final restoredLine = context.document.featureById(copiedLine.id)!;
        final restoredKind = restoredLine.kind as FeatureKindPolyline;
        final endpoint = restoredKind.resolvedGlobalPoints(restoredLine).last;
        context.document.featureById(copiedTarget.id)!.origin += const Offset(
          30,
          0,
        );
        expect(
          restoredKind.resolvedGlobalPoints(restoredLine).last,
          endpoint + const Offset(30, 0),
        );
      },
    );
  });
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

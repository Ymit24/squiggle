import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

void main() {
  group('CreateLineTool via ToolRepository', () {
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;
    late ToolRepository toolRepository;
    late TextEditRepository textEditRepository;
    late Camera camera;

    setUp(() {
      documentRepository = DocumentRepository(document: Document());
      selectionRepository = SelectionRepository();
      toolRepository = ToolRepository();
      textEditRepository = TextEditRepository();
      camera = Camera();
    });

    tearDown(() {
      toolRepository.dispose();
      textEditRepository.dispose();
      documentRepository.dispose();
    });

    void activateLineTool() {
      toolRepository.setTool(CreateLineTool(), selectionRepository);
    }

    void pointerDown(Offset world) {
      toolRepository.onPointerDown(
        documentRepository,
        world,
        selectionRepository,
        false,
        false,
        camera,
      );
    }

    void pointerMove(Offset world) {
      toolRepository.onPointerMove(
        documentRepository,
        world,
        selectionRepository,
        false,
        false,
        camera,
      );
    }

    void pointerUp(Offset world) {
      toolRepository.onPointerUp(
        documentRepository,
        world,
        selectionRepository,
        false,
        false,
        camera,
        textEditRepository,
      );
    }

    void pointerHover(Offset world) {
      toolRepository.onPointerHover(
        documentRepository,
        world,
        selectionRepository,
        false,
        false,
        camera,
      );
    }

    bool finishWithKey(LogicalKeyboardKey key) {
      return toolRepository.onKeyEvent(
        documentRepository,
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: key,
          timeStamp: Duration.zero,
        ),
      );
    }

    List<Offset> worldPointsFor(Feature feature) {
      final kind = feature.kind as FeatureKindPolyline;
      return worldPoints(feature.origin, kind.localPoints);
    }

    test('click without drag from idle enters placing without creating feature', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(documentRepository.document.features, isEmpty);
    });

    test('two clicks then Enter commits polyline with 2 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(documentRepository.document.features, isEmpty);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      final features = documentRepository.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(
        worldPointsFor(features.first),
        [const Offset(0, 0), const Offset(100, 100)],
      );
    });

    test('three clicks then Enter commits polyline with 3 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      expect(
        worldPointsFor(documentRepository.document.features.first),
        [
          const Offset(0, 0),
          const Offset(100, 0),
          const Offset(100, 100),
        ],
      );
    });

    test('three clicks then Escape commits polyline with 3 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(finishWithKey(LogicalKeyboardKey.escape), isTrue);

      expect(documentRepository.document.features, hasLength(1));
    });

    test('Enter or Escape with 1 point discards without creating feature', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);
      expect(documentRepository.document.features, isEmpty);

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.escape), isTrue);
      expect(documentRepository.document.features, isEmpty);
    });

    test('drag from idle commits 2-point line on pointer up', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(50, 50));
      pointerUp(const Offset(50, 50));

      final features = documentRepository.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(
        worldPointsFor(features.first),
        [const Offset(0, 0), const Offset(50, 50)],
      );
    });

    test('click then drag in placing mode adds point at release position', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(documentRepository.document.features, isEmpty);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      expect(
        worldPointsFor(documentRepository.document.features.first),
        [const Offset(0, 0), const Offset(100, 100)],
      );
    });

    test('deactivate mid-placement discards partial line', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      toolRepository.setTool(SelectTool(), selectionRepository);

      expect(documentRepository.document.features, isEmpty);
    });

    test('hover updates preview while placing', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(() => pointerHover(const Offset(200, 200)), returnsNormally);
    });
  });

  group('localPointsFromWorld', () {
    test('returns empty list for empty world points', () {
      expect(localPointsFromWorld([], Offset.zero), isEmpty);
    });

    test('converts world points relative to reference', () {
      expect(
        localPointsFromWorld(
          [const Offset(10, 20), const Offset(110, 120)],
          const Offset(10, 20),
        ),
        [Offset.zero, const Offset(100, 100)],
      );
    });
  });
}

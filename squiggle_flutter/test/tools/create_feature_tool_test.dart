import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';

void main() {
  group('CreateFeatureTool via ToolRepository', () {
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

    test('click without drag does not create feature', () {
      toolRepository.setTool(CreateFeatureTool.rect(), selectionRepository);

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(documentRepository.document.features, isEmpty);
    });

    test('drag creates rectangle feature', () {
      toolRepository.setTool(CreateFeatureTool.rect(), selectionRepository);

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = documentRepository.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindRectangle>());
      expect(features.first.bounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('drag creates circle feature', () {
      toolRepository.setTool(CreateFeatureTool.circle(), selectionRepository);

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = documentRepository.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindCircle>());
      expect(features.first.bounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });
  });
}

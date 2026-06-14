import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';

void main() {
  group('EditorBloc', () {
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;
    late ToolRepository toolRepository;

    setUp(() {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature.newRectangle(const Offset(0, 0), const Size(100, 100)),
        ]),
      );
      selectionRepository = SelectionRepository();
      toolRepository = ToolRepository();
    });

    tearDown(() {
      toolRepository.dispose();
      documentRepository.dispose();
    });

    test('subscribes to document changes stream via watch handler', () async {
      final bloc = EditorBloc(
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
        toolRepository: toolRepository,
      );
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      var documentChanged = false;
      final subscription = documentRepository.changesStream.listen((_) {
        documentChanged = true;
      });

      documentRepository.executeCommand(
        MoveFeatureCommand(
          documentRepository.document.features.first.id,
          const Offset(10, 10),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(documentChanged, isTrue);
      expect(
        documentRepository.document.features.first.origin,
        const Offset(10, 10),
      );
      await subscription.cancel();
      await bloc.close();
    });

    test('emits selection when repository updates', () async {
      final bloc = EditorBloc(
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
        toolRepository: toolRepository,
      );
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      await bloc.stream.firstWhere((s) => s.selectedFeatures.isNotEmpty);

      expect(bloc.state.selectedFeatures.length, 1);
      await bloc.close();
    });

    test('deletes selected features and clears selection', () async {
      final featureId = documentRepository.document.features.first.id;
      selectionRepository.selectFeature(featureId);

      final bloc = EditorBloc(
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
        toolRepository: toolRepository,
      );
      bloc.add(const DeleteSelectedFeaturesEvent());
      await Future<void>.delayed(Duration.zero);

      expect(documentRepository.document.features, isEmpty);
      expect(selectionRepository.selectedFeatures, isEmpty);
      await bloc.close();
    });
  });
}

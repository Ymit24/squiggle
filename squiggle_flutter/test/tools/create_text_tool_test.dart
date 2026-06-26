import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

void main() {
  group('CreateTextTool', () {
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;
    late ToolRepository toolRepository;
    late TextEditRepository textEditRepository;
    late TextEditBloc textEditBloc;
    late Camera camera;

    setUp(() {
      documentRepository = DocumentRepository(document: Document());
      selectionRepository = SelectionRepository();
      toolRepository = ToolRepository();
      textEditRepository = TextEditRepository();
      textEditBloc = TextEditBloc(
        documentRepository: documentRepository,
        textEditRepository: textEditRepository,
      );
      textEditBloc.add(const RequestWatchTextEditStateEvent());
      camera = Camera();
    });

    tearDown(() async {
      await textEditBloc.close();
      toolRepository.dispose();
      textEditRepository.dispose();
      documentRepository.dispose();
    });

    test('resolves crosshair cursor', () {
      toolRepository.setTool(CreateTextTool(), selectionRepository);

      expect(
        toolRepository.resolveCursor(
          documentRepository,
          Offset.zero,
          selectionRepository,
          camera,
        ),
        EditorCursor.crosshair,
      );
    });

    test('click opens create text edit session without adding feature', () async {
      toolRepository.setTool(CreateTextTool(), selectionRepository);
      const click = Offset(50, 75);

      toolRepository.onPointerUp(
        documentRepository,
        click,
        selectionRepository,
        false,
        false,
        camera,
        textEditRepository,
      );

      expect(documentRepository.document.features, isEmpty);

      final openState = await textEditBloc.stream.firstWhere(
        (state) => state is CreateTextEditOpen,
      ) as CreateTextEditOpen;

      expect(openState.worldOrigin, click);
      expect(openState.initialContents, '');
      expect(
        openState.canvasLocalBounds,
        camera.worldToScreenBounds(newTextBoundsAt(click)),
      );
    });

    test('document unchanged until modal submit', () async {
      toolRepository.setTool(CreateTextTool(), selectionRepository);

      toolRepository.onPointerUp(
        documentRepository,
        const Offset(50, 75),
        selectionRepository,
        false,
        false,
        camera,
        textEditRepository,
      );
      await textEditBloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      expect(documentRepository.document.features, isEmpty);

      textEditBloc.add(const TextEditSubmitted('hello'));
      await textEditBloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(documentRepository.document.features, hasLength(1));
      expect(
        (documentRepository.document.features.first.kind as FeatureKindText)
            .contents,
        'hello',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

void main() {
  group('CreateTextTool', () {
    late EditorContext context;
    late TextEditBloc textEditBloc;
    late Camera camera;

    setUp(() {
      context = EditorContext(document: Document());
      textEditBloc = TextEditBloc(context: context);
      textEditBloc.add(const RequestWatchTextEditStateEvent());
      camera = Camera();
    });

    tearDown(() async {
      await textEditBloc.close();
      context.dispose();
    });

    test('resolves crosshair cursor', () {
      context.setTool(CreateTextTool());

      expect(
        context.tool.resolveCursor(context, Offset.zero, camera),
        EditorCursor.crosshair,
      );
    });

    test('click opens create text edit session without adding feature', () async {
      context.setTool(CreateTextTool());
      const click = Offset(50, 75);

      context.tool.onPointerUp(
        context,
        click,
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );

      expect(context.document.features, isEmpty);

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
      context.setTool(CreateTextTool());

      context.tool.onPointerUp(
        context,
        const Offset(50, 75),
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );
      await textEditBloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      expect(context.document.features, isEmpty);

      textEditBloc.add(const TextEditSubmitted('hello'));
      await textEditBloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.features, hasLength(1));
      expect(
        (context.document.features.first.kind as FeatureKindText).contents,
        'hello',
      );
    });
  });
}

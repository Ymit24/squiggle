import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_commands.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  group('CreateTextTool', () {
    late EditorContext context;
    late Camera camera;

    setUp(() {
      context = EditorContext(document: Document());
      camera = Camera();
    });

    tearDown(() => context.dispose());

    test('resolves crosshair cursor', () {
      context.setTool(CreateTextTool());

      expect(
        context.tool.resolveCursor(context, Offset.zero, camera),
        EditorCursor.crosshair,
      );
    });

    test(
      'click opens create text edit session without adding feature',
      () async {
        context.setTool(CreateTextTool());
        const click = Offset(50, 75);

        context.tool.onPointerUp(
          context,
          click,
          camera,
          isShiftPressed: false,
          isAltPressed: false,
        );

        expect(context.document.nodes, isEmpty);
        expect(context.tool.activeTool, isA<SelectTool>());

        final openState = context.textEdit.session as CreateTextEditSession;

        expect(openState.worldOrigin, click);
        expect(openState.initialContents, '');
        expect(openState.layout.bounds.topLeft, click);
        expect(openState.layout.bounds.width, defaultNewTextWidth);
      },
    );

    test(
      'locked text tool stays ready after submit and empty submit',
      () async {
        context.tool.toggleLock();
        context.setTool(CreateTextTool());
        final textTool = context.tool.activeTool;

        for (final submit in [true, false]) {
          final click = submit ? const Offset(50, 75) : const Offset(150, 175);
          context.tool.onPointerUp(
            context,
            click,
            camera,
            isShiftPressed: false,
            isAltPressed: false,
          );
          final open = context.textEdit.session as CreateTextEditSession;
          expect(open.worldOrigin, click);
          expect(context.tool.activeTool, same(textTool));

          commitTextEdit(context, contents: submit ? 'hello' : '');
          expect(context.tool.activeTool, same(textTool));
          expect(context.textEdit.session, isNull);
        }
        expect(context.document.nodes, hasLength(1));
        expect(context.selection.isEmpty, isTrue);
      },
    );

    test('document unchanged until the edit commits', () async {
      context.setTool(CreateTextTool());

      context.tool.onPointerUp(
        context,
        const Offset(50, 75),
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );

      expect(context.document.nodes, isEmpty);

      commitTextEdit(context, contents: 'hello');

      expect(context.document.nodes, hasLength(1));
      expect(context.selection.selectedNodeIds, [
        context.document.nodes.first.id,
      ]);
      expect(
        ((context.document.nodes.first as Feature).kind as FeatureKindText)
            .label,
        'hello',
      );
    });
  });
}

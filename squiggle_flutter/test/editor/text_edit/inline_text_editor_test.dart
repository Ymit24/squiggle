import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/inline_text_editor.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/painting/text_painter.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

const _text =
    'The quick brown fox jumps over the lazy dog, repeatedly.\nSecond';

void main() {
  for (final zoom in [0.5, 1.0, 2.5]) {
    for (final alignment in TextHorizontalAlignment.values) {
      testWidgets(
        'edit field matches painted layout at zoom $zoom, $alignment',
        (tester) async {
          final layout = LabelLayout(
            bounds: const Rect.fromLTWH(40, 30, 180, 100),
            fontSize: 20,
            color: Colors.white,
            horizontalAlignment: alignment,
            verticalAlignment: TextVerticalAlignment.center,
          );
          final editorContext = EditorContext(document: Document());
          addTearDown(editorContext.dispose);
          final camera = editorContext.camera..zoom = zoom;
          final controller = TextEditingController(text: _text);
          addTearDown(controller.dispose);
          final focusNode = FocusNode();
          addTearDown(focusNode.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: SquiggleThemeData.dark(),
              home: Stack(
                children: [
                  InlineTextEditor(
                    controller: controller,
                    focusNode: focusNode,
                    layout: () => layout,
                    editorContext: editorContext,
                    onTapOutside: () {},
                  ),
                ],
              ),
            ),
          );

          // Same wrap width and style as the painter means the same line count.
          final painted = measureText(
            _text,
            width: layout.bounds.width,
            fontSize: layout.fontSize,
            horizontalAlignment: alignment,
          );
          final field = tester.getRect(find.byType(TextField));
          expect(field.height, closeTo(painted.height / zoom, 0.01));

          final expectedTopLeft = camera.worldToScreen(
            layout.textOrigin(_text),
          );
          expect(field.topLeft.dx, closeTo(expectedTopLeft.dx, 0.01));
          expect(field.topLeft.dy, closeTo(expectedTopLeft.dy, 0.01));
        },
      );
    }
  }

  group('with an editor context', () {
    late EditorContext editorContext;
    late TextEditingController controller;
    late FocusNode focusNode;
    var tappedOutside = 0;

    setUp(() {
      editorContext = EditorContext(document: Document());
      controller = TextEditingController(text: 'hello');
      focusNode = FocusNode();
      tappedOutside = 0;
    });

    tearDown(() {
      editorContext.dispose();
      controller.dispose();
      focusNode.dispose();
    });

    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Stack(
          children: [
            // Stands in for the canvas: tap regions only see taps that hit
            // something.
            const Positioned.fill(
              child: Listener(behavior: HitTestBehavior.opaque),
            ),
            InlineTextEditor(
              controller: controller,
              focusNode: focusNode,
              layout: () => const LabelLayout(
                bounds: Rect.fromLTWH(100, 100, 200, 40),
                fontSize: 20,
                color: Colors.white,
                horizontalAlignment: TextHorizontalAlignment.left,
                verticalAlignment: TextVerticalAlignment.top,
              ),
              editorContext: editorContext,
              onTapOutside: () => tappedOutside++,
            ),
          ],
        ),
      ),
    );

    testWidgets('follows camera zoom and pan while open', (tester) async {
      await pump(tester);
      final before = tester.getRect(find.byType(TextField));

      editorContext.camera
        ..zoom = 0.5
        ..location = const Offset(50, 0);
      editorContext.notifyViewportChanged();
      await tester.pump();

      final after = tester.getRect(find.byType(TextField));
      expect(after.height, closeTo(before.height * 2, 0.01));
      expect(after.topLeft.dx, closeTo((100 - 50) / 0.5, 0.01));
    });

    testWidgets(
      'tapping outside the field reports it, tapping inside does not',
      (tester) async {
        await pump(tester);
        await tester.pump(); // autofocus lands after the first frame

        await tester.tapAt(const Offset(110, 110));
        expect(tappedOutside, 0);

        await tester.tapAt(const Offset(700, 500));
        expect(tappedOutside, 1);
      },
    );
  });
}

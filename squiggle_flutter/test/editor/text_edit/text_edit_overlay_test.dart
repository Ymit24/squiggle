import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/widgets/pointer_claims.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  testWidgets('edit field follows its feature when the feature moves', (
    tester,
  ) async {
    final rect = Feature(
      origin: const Offset(100, 100),
      size: const Size(200, 100),
      kind: FeatureKindRectangle(label: 'label'),
    );
    final editor = EditorContext(document: Document.fromFeatures([rect]));
    addTearDown(editor.dispose);
    final session = EditTextEditSession.forFeature(rect);
    editor.startTextEdit(session);

    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Stack(
          children: [
            TextEditOverlay(
              session: session,
              pointerClaims: PointerClaims(),
              editorContext: editor,
            ),
          ],
        ),
      ),
    );
    final before = tester.getTopLeft(find.byType(TextField));

    rect.origin += const Offset(150, 40);
    editor.notifyViewportChanged();
    await tester.pump();

    expect(
      tester.getTopLeft(find.byType(TextField)) - before,
      const Offset(150, 40),
    );
  });

  testWidgets('typing keeps the draft current for outside commits', (
    tester,
  ) async {
    final rect = Feature(
      origin: const Offset(100, 100),
      size: const Size(200, 100),
      kind: FeatureKindRectangle(label: 'label'),
    );
    final editor = EditorContext(document: Document.fromFeatures([rect]));
    addTearDown(editor.dispose);
    final session = EditTextEditSession.forFeature(rect);
    editor.startTextEdit(session);

    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Stack(
          children: [
            TextEditOverlay(
              session: session,
              pointerClaims: PointerClaims(),
              editorContext: editor,
            ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hello');

    expect(editor.textEdit.draft, 'hello');
  });
}

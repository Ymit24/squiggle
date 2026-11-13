import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/canvas_preferences.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/editor/widgets/document_canvas.dart';
import 'package:squiggle_flutter/editor/widgets/document_viewport.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';
import 'package:squiggle_flutter/preferences/widgets/canvas_section.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_switch.dart';

import '../support/test_preferences.dart';

void main() {
  late Preferences preferences;

  setUp(() => preferences = testPreferences());

  Future<void> pumpWithPreferences(WidgetTester tester, Widget child) =>
      tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: preferences,
          child: MaterialApp(
            theme: SquiggleThemeData.dark(),
            home: Scaffold(body: child),
          ),
        ),
      );

  Future<void> setShowGrid(WidgetTester tester, bool value) async {
    await preferences.set(showGridPreference, value);
    await tester.pump();
  }

  testWidgets('the canvas paints the grid only while the preference is on', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    final images = ImageRepository();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      images.dispose();
      editor.dispose();
    });
    await pumpWithPreferences(
      tester,
      DocumentViewport(editorContext: editor, imageRepository: images),
    );
    RenderDocumentCanvas canvas() =>
        tester.renderObject(find.byType(DocumentCanvas));

    expect(canvas().showGrid, isTrue);
    await setShowGrid(tester, false);
    expect(canvas().showGrid, isFalse);
    await setShowGrid(tester, true);
    expect(canvas().showGrid, isTrue);
  });

  testWidgets("Cmd+' and Ctrl+' toggle the grid in the editor", (tester) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    await pumpWithPreferences(
      tester,
      ChangeNotifierProvider.value(
        value: editor,
        child: ToolShortcuts(child: const SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> press(LogicalKeyboardKey modifier) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.quote);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
    }

    await press(LogicalKeyboardKey.metaLeft);
    expect(preferences.get(showGridPreference), isFalse);
    await press(LogicalKeyboardKey.controlLeft);
    expect(preferences.get(showGridPreference), isTrue);
  });

  testWidgets('the Canvas section toggles the grid from the row or switch', (
    tester,
  ) async {
    await pumpWithPreferences(tester, const CanvasSection());

    await tester.tap(find.text('Show grid'));
    await tester.pump();
    expect(preferences.get(showGridPreference), isFalse);
    expect(
      tester.widget<SquiggleSwitch>(find.byType(SquiggleSwitch)).value,
      isFalse,
    );

    await tester.tap(find.byType(SquiggleSwitch));
    await tester.pump();
    expect(preferences.get(showGridPreference), isTrue);
  });
}

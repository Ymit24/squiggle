import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_add_slot.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/brush_name_dialog.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  const pointer = Offset(700, 450);

  Future<TestGesture> mount(WidgetTester tester, EditorContext editor) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: MultiProvider(
          providers: [
            Provider<EditorContext>.value(value: editor),
            Provider<ImageRepository>(create: (_) => ImageRepository()),
          ],
          child: Scaffold(
            body: Editor(editorContext: editor, onBackToLibrary: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: pointer);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(pointer);
    await tester.pump();
    return mouse;
  }

  /// Rect tool with Scratch, Ink (active) and Blueprint.
  EditorContext drawingEditor() {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.rect());
    final ink = editor.brushes.create('Ink');
    editor.brushes.create('Blueprint');
    editor.brushes.activate(ink.id);
    return editor;
  }

  Offset slot(EditorContext editor, int index) =>
      pointer +
      BrushWheelGeometry.slotCenter(
        index,
        editor.brushes.profiles.length + (editor.brushes.canCreate ? 1 : 0),
      );

  testWidgets('holding B opens the wheel and releasing activates the '
      'hovered brush', (tester) async {
    final editor = drawingEditor();
    final mouse = await mount(tester, editor);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(find.byType(BrushWheel), findsOneWidget);
    expect(find.text('Release to cancel'), findsOneWidget);

    await mouse.moveTo(slot(editor, 2));
    await tester.pump();
    expect(tester.widget<BrushWheel>(find.byType(BrushWheel)).hoveredIndex, 2);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(find.byType(BrushWheel), findsNothing);
    expect(editor.brushes.active.name, 'Blueprint');
  });

  testWidgets('releasing on the add slot opens the name dialog', (
    tester,
  ) async {
    final editor = drawingEditor();
    final mouse = await mount(tester, editor);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await mouse.moveTo(slot(editor, 3));
    await tester.pump();
    expect(find.text('New brush…'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(find.byType(BrushWheel), findsNothing);
    expect(find.byType(BrushNameDialog), findsOneWidget);
  });

  testWidgets('the add slot is hidden at nine brushes', (tester) async {
    final editor = drawingEditor();
    while (editor.brushes.canCreate) {
      editor.brushes.create('Extra');
    }
    await mount(tester, editor);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(find.byType(BrushWheelAddSlot), findsNothing);
  });

  testWidgets('releasing in the hub or outside the wheel changes nothing', (
    tester,
  ) async {
    final editor = drawingEditor();
    final mouse = await mount(tester, editor);

    for (final release in [pointer, pointer + const Offset(0, -200)]) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      await mouse.moveTo(slot(editor, 0));
      await tester.pump();
      await mouse.moveTo(release);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      expect(editor.brushes.active.name, 'Ink');
      await mouse.moveTo(pointer);
      await tester.pump();
    }
  });

  testWidgets('releasing on the active brush keeps it', (tester) async {
    final editor = drawingEditor();
    final mouse = await mount(tester, editor);
    var notifications = 0;
    editor.brushes.addListener(() => notifications++);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await mouse.moveTo(slot(editor, 1));
    await tester.pump();
    expect(find.textContaining('current', findRichText: true), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();

    expect(editor.brushes.active.name, 'Ink');
    expect(notifications, 0);
  });

  testWidgets('Escape cancels and shortcuts work again afterwards', (
    tester,
  ) async {
    final editor = drawingEditor();
    final mouse = await mount(tester, editor);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    await mouse.moveTo(slot(editor, 2));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(BrushWheel), findsNothing);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(editor.brushes.active.name, 'Ink');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(editor.tool.activeTool, isA<SelectTool>());
  });

  testWidgets('the wheel stays closed without a drawing tool', (tester) async {
    final editor = drawingEditor();
    editor.setTool(SelectTool());
    await mount(tester, editor);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(find.byType(BrushWheel), findsNothing);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
  });
}

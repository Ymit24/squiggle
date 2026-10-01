import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_menu_entry.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_dropdown.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/stroke_width_selector.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

void main() {
  setUpAll(() async {
    Provider.debugCheckInvalidValueType = null;
  });

  Future<void> mount(
    WidgetTester tester,
    EditorContext editor,
    GlobalKey capture,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: MaterialApp(
          theme: SquiggleThemeData.dark(),
          debugShowCheckedModeBanner: false,
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
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('repeated mouse drags while hovering handles keep rows mounted', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.rect());
    final actual = editor.brushes.create('Normal');
    final construction = editor.brushes.create('Construction');
    editor.brushes.create('Notes');
    editor.brushes.create('Warnings');
    await mount(tester, editor, GlobalKey());
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    for (var i = 0; i < 8; i++) {
      final named = editor.brushes.profiles.skip(1).toList();
      final targetRow = tester.getCenter(find.byKey(ValueKey(named.first.id)));
      final source = tester.getCenter(
        find.byKey(ValueKey('brush-drag-${named.last.id}')),
      );
      // Keep hovering the handle after dropping, rather than the row label.
      final target = Offset(source.dx, targetRow.dy);
      await mouse.moveTo(source);
      await tester.pump(const Duration(milliseconds: 800));
      await mouse.down(source);
      final drag = mouse;
      await drag.moveBy(const Offset(0, -24));
      await tester.pump();
      await drag.moveTo(target);
      await tester.pump(const Duration(milliseconds: 400));
      await drag.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(editor.brushes.profiles.map((brush) => brush.id), [
        'scratch',
        named.last.id,
        ...named.take(named.length - 1).map((brush) => brush.id),
      ]);
      expect(find.byKey(ValueKey(actual.id)), findsOneWidget);
      expect(find.byKey(ValueKey(construction.id)), findsOneWidget);
    }
  });

  testWidgets(
    'handle drag commits on drop without selecting or closing the menu',
    (tester) async {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setTool(CreateFeatureTool.rect());
      final actual = editor.brushes.create('Actual');
      final construction = editor.brushes.create('Construction');
      final notes = editor.brushes.create('Notes');
      editor.brushes.activate(actual.id);
      await mount(tester, editor, GlobalKey());
      await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brush-drag-scratch')), findsNothing);
      final original = editor.brushes.profiles
          .map((brush) => brush.id)
          .toList();
      final target = tester.getCenter(find.byKey(ValueKey(actual.id)));
      final drag = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('brush-drag-${notes.id}'))),
      );
      await drag.moveBy(const Offset(0, -24));
      await tester.pump();
      await drag.moveTo(target);
      await tester.pump(const Duration(milliseconds: 400));
      expect(editor.brushes.profiles.map((brush) => brush.id), original);
      expect(editor.brushes.active.id, actual.id);
      expect(find.byType(BrushDropdown), findsOneWidget);
      await drag.up();
      await tester.pumpAndSettle();
      expect(editor.brushes.profiles.map((brush) => brush.id), [
        'scratch',
        notes.id,
        actual.id,
        construction.id,
      ]);
      expect(editor.brushes.active.id, actual.id);
      expect(find.byType(BrushDropdown), findsOneWidget);
      final entries = tester
          .widgetList<BrushMenuEntry>(find.byType(BrushMenuEntry))
          .toList();
      expect(entries.map((entry) => entry.brush.id), [
        'scratch',
        notes.id,
        actual.id,
        construction.id,
      ]);
      expect(entries.map((entry) => entry.shortcutNumber), [1, 2, 3, 4]);
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.id, notes.id);
      expect(find.byType(BrushDropdown), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(editor.brushes.active.id, actual.id);
    },
  );

  testWidgets('cancelled drag leaves brush order unchanged', (tester) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.rect());
    final actual = editor.brushes.create('Actual');
    final notes = editor.brushes.create('Notes');
    await mount(tester, editor, GlobalKey());
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    final target = tester.getCenter(find.byKey(ValueKey(actual.id)));
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('brush-drag-${notes.id}'))),
    );
    await drag.moveBy(const Offset(0, -24));
    await tester.pump();
    await drag.moveTo(target);
    await tester.pump(const Duration(milliseconds: 400));
    await drag.cancel();
    await tester.pumpAndSettle();
    expect(editor.brushes.profiles.map((brush) => brush.id), [
      'scratch',
      actual.id,
      notes.id,
    ]);
    expect(find.byType(BrushDropdown), findsOneWidget);
  });

  testWidgets('short popup scrolls profiles with Scratch and Create visible', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.rect());
    for (var index = 1; index < 9; index++) {
      editor.brushes.create('Brush $index');
    }
    await mount(tester, editor, GlobalKey());
    tester.view.physicalSize = const Size(1280, 400);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Scratch').hitTestable(), findsOneWidget);
    expect(find.text('Create brush').hitTestable(), findsOneWidget);
    final list = find.byKey(const ValueKey('brush-reorder-list'));
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Brush 8').hitTestable(), findsOneWidget);
    expect(find.text('Scratch').hitTestable(), findsOneWidget);
    expect(find.text('Create brush').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'brush shortcuts follow menu order and only switch before drawing',
    (tester) async {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setTool(CreateFeatureTool.rect());
      final actual = editor.brushes.create('Actual');
      final construction = editor.brushes.create('Construction');
      await mount(tester, editor, GlobalKey());
      Future<void> shortcut(LogicalKeyboardKey key, {bool meta = true}) async {
        final modifier = meta
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft;
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();
      }

      await shortcut(LogicalKeyboardKey.digit1);
      expect(editor.brushes.active.isScratch, isTrue);
      await shortcut(LogicalKeyboardKey.digit2, meta: false);
      expect(editor.brushes.active.id, actual.id);
      await shortcut(LogicalKeyboardKey.digit9);
      expect(editor.brushes.active.id, actual.id);
      expect(editor.tool.activeTool, isA<CreateFeatureTool>());
      final feature = editor.document.addNode(
        Feature(
          origin: const Offset(400, 200),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      );
      editor.selection.setSelection([feature.id]);
      await tester.pumpAndSettle();
      await shortcut(LogicalKeyboardKey.digit3);
      expect(editor.brushes.active.id, actual.id);
      editor.selection.clearSelection();
      editor.setTool(SelectTool());
      await tester.pumpAndSettle();
      await shortcut(LogicalKeyboardKey.digit3);
      expect(editor.brushes.active.id, actual.id);
      editor.setTool(CreateFeatureTool.rect());
      editor.brushes.delete(actual.id);
      await tester.pumpAndSettle();
      await shortcut(LogicalKeyboardKey.digit2);
      expect(editor.brushes.active.id, construction.id);
      expect(editor.history.canUndo, isFalse);
    },
  );

  testWidgets('nine brushes disable Create until a brush is deleted', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.rect());
    for (var index = 1; index < 9; index++) {
      editor.brushes.create('Brush $index');
    }
    final last = editor.brushes.active;
    expect(editor.document.session.brushes, hasLength(9));
    expect(() => editor.brushes.create('Overflow'), throwsStateError);
    await mount(tester, editor, GlobalKey());
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    expect(find.byType(BrushMenuEntry), findsNWidgets(9));
    expect(
      tester
          .widget<BrushMenuEntry>(find.byType(BrushMenuEntry).first)
          .shortcutNumber,
      1,
    );
    expect(
      tester
          .widget<BrushMenuEntry>(find.byType(BrushMenuEntry).last)
          .shortcutNumber,
      9,
    );
    final create = find.widgetWithText(SquiggleMenuItem, 'Create brush');
    expect(tester.widget<SquiggleMenuItem>(create).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    editor.brushes.delete(last.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
    await tester.pumpAndSettle();
    expect(tester.widget<SquiggleMenuItem>(create).onPressed, isNotNull);
  });

  testWidgets(
    'creating from picker copies active values and switching restores them',
    (tester) async {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setTool(CreateFeatureTool.rect());
      editor.brushes.setField('strokeColor', Colors.orange.toARGB32());
      await mount(tester, editor, GlobalKey());
      await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create brush'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Construction');
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.name, 'Construction');
      expect(editor.brushes.active.values, {
        'strokeColor': Colors.orange.toARGB32(),
      });
      editor.brushes.setField('strokeWidth', 3.0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scratch'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.values, {
        'strokeColor': Colors.orange.toARGB32(),
      });
      expect(find.byKey(const ValueKey('brush-actions-trigger')), findsNothing);
    },
  );

  testWidgets(
    'drawing edits change brush; selected edits and undo leave it alone',
    (tester) async {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setTool(CreateFeatureTool.rect());
      await mount(tester, editor, GlobalKey());
      tester
          .widget<StrokeWidthSelector>(find.byType(StrokeWidthSelector))
          .onPresetSelected(StrokeWidthPreset.thin);
      await tester.pumpAndSettle();
      expect(editor.brushes.active.values['strokeWidth'], 3.0);
      expect(editor.history.canUndo, isFalse);
      expect(find.byTooltip('Clear brush override'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear brush override'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.values, isEmpty);

      final feature =
          editor.document.addNode(
                Feature(
                  origin: const Offset(400, 220),
                  size: const Size(180, 120),
                  kind: FeatureKindRectangle(),
                ),
              )
              as Feature;
      editor.selection.setSelection([feature.id]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brush-picker-trigger')), findsNothing);
      tester
          .widget<StrokeWidthSelector>(find.byType(StrokeWidthSelector))
          .onPresetSelected(StrokeWidthPreset.thick);
      await tester.pumpAndSettle();
      expect((feature.kind as FeatureKindRectangle).strokeWidth, 16.0);
      expect(editor.brushes.active.values, isEmpty);
      expect(find.byTooltip('Clear brush override'), findsNothing);
      editor.undo();
      await tester.pumpAndSettle();
      expect(
        (feature.kind as FeatureKindRectangle).strokeWidth,
        defaultStrokeWidth,
      );
      editor.setTool(SelectTool());
      editor.selection.clearSelection();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brush-picker-trigger')), findsNothing);
      expect(find.byType(StrokeWidthSelector), findsNothing);
      editor.setTool(CreateFeatureTool.rect());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('brush-picker-trigger')),
        findsOneWidget,
      );
      expect(find.byType(StrokeWidthSelector), findsOneWidget);
    },
  );

  testWidgets(
    'picker, management, rename and delete are mutually exclusive and preserve styles',
    (tester) async {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setTool(CreateFeatureTool.rect());
      editor.document.session.brushes.addAll([
        BrushProfile(
          id: 'construction',
          name: 'Construction',
          values: {
            'strokeColor': const Color(0xFFDB963F).toARGB32(),
            'strokeType': StrokeType.dashed.name,
            'strokeWidth': 3.0,
            'fillColor': Colors.transparent.toARGB32(),
          },
        ),
        BrushProfile(
          id: 'notes',
          name: 'Notes',
          values: {
            'strokeColor': const Color(0xFF4976B8).toARGB32(),
            'fontSize': 24.0,
          },
        ),
        BrushProfile(
          id: 'warnings',
          name: 'Warnings',
          values: {
            'strokeColor': const Color(0xFFE45B5B).toARGB32(),
            'fontSize': 24.0,
          },
        ),
      ]);
      final actual = editor.brushes.create('Actual');
      // Preview fixtures are document-local profiles, not built-in defaults.
      editor.document.session.brushes.remove(actual);
      editor.document.session.brushes.insert(2, actual);
      editor.brushes.setField('strokeWidth', 8.0);
      editor.brushes.setField('strokeColor', Colors.white.toARGB32());
      editor.brushes.setField('endEndCap', LineEndCap.arrow.name);
      editor.document.addNode(
        Feature(
          origin: const Offset(430, 200),
          size: const Size(240, 150),
          kind: FeatureKindRectangle(
            fillColor: Colors.transparent,
            strokeColor: Colors.white,
          ),
        ),
      );
      editor.document.addNode(
        Feature(
          origin: const Offset(800, 390),
          size: const Size(160, 160),
          kind: FeatureKindCircle(
            fillColor: Colors.transparent,
            strokeColor: const Color(0xFFDB963F),
            strokeType: StrokeType.dashed,
            strokeWidth: 3,
          ),
        ),
      );
      editor.document.addNode(
        Feature(
          origin: const Offset(530, 440),
          size: const Size(240, 60),
          kind: FeatureKindText(
            'Brush profiles',
            strokeColor: const Color(0xFF4976B8),
          ),
        ),
      );
      final capture = GlobalKey();
      await mount(tester, editor, capture);
      await tester.tap(find.byKey(const ValueKey('brush-picker-trigger')));
      await tester.pumpAndSettle();
      expect(find.byType(BrushMenuEntry), findsNWidgets(5));
      await tester.tap(find.byKey(const ValueKey('brush-actions-trigger')));
      await tester.pumpAndSettle();
      expect(find.byType(BrushMenuEntry), findsNothing);
      expect(find.text('Rename…'), findsOneWidget);
      await tester.tap(find.text('Rename…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Actual geometry');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.name, 'Actual geometry');
      await tester.tap(find.byKey(const ValueKey('brush-actions-trigger')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete brush'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(editor.brushes.active.isScratch, isTrue);
      expect(
        editor.document.session.brushes.any((brush) => brush.id == actual.id),
        isFalse,
      );
      expect(editor.brushes.active.values['strokeWidth'], 8.0);
      expect(find.byKey(const ValueKey('brush-actions-trigger')), findsNothing);
      expect(editor.history.canUndo, isFalse);
    },
  );
}

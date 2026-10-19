import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/editor/widgets/editor_interactions.dart';
import 'package:squiggle_flutter/editor/widgets/pointer_claims.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

Future<EditorContext> _pumpEditor(
  WidgetTester tester, {
  Document? document,
  PointerClaims? claims,
  Widget? overlay,
  Widget? underlay,
  Feature? editing,
}) async {
  final editor = EditorContext(document: document ?? Document());
  final session = editing == null
      ? null
      : EditTextEditSession.forFeature(editing);
  if (session != null) editor.startTextEdit(session);
  final canvasKey = GlobalKey();
  final pointerClaims = claims ?? PointerClaims();
  final images = ImageRepository();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    images.dispose();
    editor.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: SquiggleThemeData.dark(),
      home: EditorInteractions(
        context: editor,
        canvasKey: canvasKey,
        imageRepository: images,
        pointerClaims: pointerClaims,
        child: Stack(
          children: [
            SizedBox.expand(key: canvasKey),
            ?underlay,
            ?overlay,
            if (session != null)
              TextEditOverlay(
                session: session,
                pointerClaims: pointerClaims,
                editorContext: editor,
              ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return editor;
}

Future<void> _rightClick(WidgetTester tester, Offset position) async {
  final gesture = await tester.startGesture(
    position,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

Feature _rectangle(Offset origin) => Feature(
  origin: origin,
  size: const Size(100, 100),
  kind: FeatureKindRectangle(),
);

void main() {
  testWidgets('Select All selects the document and dismisses the menu', (
    tester,
  ) async {
    final first = _rectangle(const Offset(100, 100));
    final second = _rectangle(const Offset(300, 300));
    final editor = await _pumpEditor(
      tester,
      document: Document.fromFeatures([first, second]),
    );
    await _rightClick(tester, const Offset(600, 400));
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();

    expect(editor.selection.selectedNodeIds, [first.id, second.id]);
    expect(find.byType(ContextMenu), findsNothing);
    expect(editor.history.canUndo, isFalse);
  });

  testWidgets('Escape dismisses the menu without changing the selection', (
    tester,
  ) async {
    final feature = _rectangle(const Offset(100, 100));
    final editor = await _pumpEditor(
      tester,
      document: Document.fromFeatures([feature]),
    );
    await _rightClick(tester, const Offset(150, 150));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(ContextMenu), findsNothing);
    expect(editor.selection.selectedNodeIds, [feature.id]);
    expect(editor.document.nodeById(feature.id), same(feature));
    expect(editor.history.canUndo, isFalse);
  });

  testWidgets('menu stays within the viewport near its bottom right corner', (
    tester,
  ) async {
    final feature = _rectangle(const Offset(680, 480));
    await _pumpEditor(tester, document: Document.fromFeatures([feature]));
    await _rightClick(tester, const Offset(750, 550));

    final menuBounds = tester.getRect(find.byType(ContextMenu));
    expect(menuBounds.left, greaterThanOrEqualTo(0));
    expect(menuBounds.top, greaterThanOrEqualTo(0));
    expect(menuBounds.right, lessThanOrEqualTo(800));
    expect(menuBounds.bottom, lessThanOrEqualTo(600));
  });

  testWidgets('releasing a context click clears secondary pointer state', (
    tester,
  ) async {
    final editor = await _pumpEditor(tester);
    await _rightClick(tester, const Offset(300, 300));
    expect(find.byType(ContextMenu), findsOneWidget);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(find.byType(ContextMenu), findsNothing);

    final middle = await tester.startGesture(
      const Offset(300, 300),
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.moveBy(const Offset(40, 0));
    await middle.up();
    await tester.pumpAndSettle();
    expect(editor.camera.location, Offset.zero);
    expect(find.byType(ContextMenu), findsNothing);
  });

  testWidgets('a right drag keeps panning back to its start without a menu', (
    tester,
  ) async {
    final editor = await _pumpEditor(tester);
    final right = await tester.startGesture(
      const Offset(300, 300),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await right.moveBy(const Offset(60, 0));
    expect(editor.camera.location, const Offset(-60, 0));
    await right.moveBy(const Offset(-57, 0));
    expect(editor.camera.location, const Offset(-3, 0));
    await right.moveBy(const Offset(-3, 0));
    await right.up();
    await tester.pumpAndSettle();
    expect(editor.camera.location, Offset.zero);
    expect(find.byType(ContextMenu), findsNothing);

    await _rightClick(tester, const Offset(300, 300));
    expect(find.byType(ContextMenu), findsOneWidget);
  });

  testWidgets('small right-click movement opens the menu without panning', (
    tester,
  ) async {
    final editor = await _pumpEditor(tester);
    final right = await tester.startGesture(
      const Offset(300, 300),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await right.moveBy(const Offset(3, 0));
    await right.up();
    await tester.pumpAndSettle();
    expect(editor.camera.location, Offset.zero);
    expect(find.byType(ContextMenu), findsOneWidget);
  });

  testWidgets('cancelling a right drag allows the next context click', (
    tester,
  ) async {
    await _pumpEditor(tester);
    final right = await tester.startGesture(
      const Offset(300, 300),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await right.moveBy(const Offset(60, 0));
    await right.cancel();
    await tester.pumpAndSettle();
    expect(find.byType(ContextMenu), findsNothing);
    await _rightClick(tester, const Offset(300, 300));
    expect(find.byType(ContextMenu), findsOneWidget);
  });

  testWidgets('right-click selects the topmost node at the world position', (
    tester,
  ) async {
    final original = _rectangle(Offset.zero);
    final underneath = _rectangle(const Offset(680, 680));
    final target = _rectangle(const Offset(690, 690));
    final editor = await _pumpEditor(
      tester,
      document: Document.fromFeatures([original, underneath, target]),
    );
    editor.selection.selectNode(original.id);
    editor.camera.location = const Offset(100, 100);
    editor.camera.zoom = 2;

    await _rightClick(tester, const Offset(300, 300));
    expect(editor.selection.selectedNodeIds, [target.id]);
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(editor.document.nodeById(target.id), isNull);
    expect(editor.document.nodeById(original.id), same(original));
    expect(editor.document.nodeById(underneath.id), same(underneath));
    expect(editor.selection.isEmpty, isTrue);
    expect(find.byType(ContextMenu), findsNothing);
    editor.undo();
    expect(editor.document.nodeById(target.id), isNotNull);
    editor.redo();
    expect(editor.document.nodeById(target.id), isNull);
    expect(editor.document.nodeById(original.id), same(original));
    expect(editor.document.nodeById(underneath.id), same(underneath));
  });

  testWidgets('right-click preserves selection on selected nodes and canvas', (
    tester,
  ) async {
    final first = _rectangle(const Offset(100, 100));
    final second = _rectangle(const Offset(300, 300));
    final editor = await _pumpEditor(
      tester,
      document: Document.fromFeatures([first, second]),
    );
    editor.selection.setSelection([first.id, second.id]);

    await _rightClick(tester, const Offset(350, 350));
    expect(editor.selection.selectedNodeIds, [first.id, second.id]);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    await _rightClick(tester, const Offset(600, 400));
    expect(editor.selection.selectedNodeIds, [first.id, second.id]);
  });

  group('while editing text', () {
    Future<(EditorContext, Feature)> pumpEditing(WidgetTester tester) async {
      final rect = _rectangle(const Offset(100, 100));
      final editor = await _pumpEditor(
        tester,
        document: Document.fromFeatures([rect]),
        editing: rect,
      );
      editor.textEdit.draft = 'typed';
      return (editor, rect);
    }

    testWidgets('pressing empty canvas commits the draft', (tester) async {
      final (editor, rect) = await pumpEditing(tester);

      await tester.tapAt(const Offset(600, 400));
      await tester.pumpAndSettle();

      expect(editor.textEdit.session, isNull);
      expect((rect.kind as FeatureKindRectangle).label, 'typed');
    });

    testWidgets('pressing the text field itself keeps the edit open', (
      tester,
    ) async {
      final (editor, _) = await pumpEditing(tester);
      final session = editor.textEdit.session;

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(editor.textEdit.session, same(session));
      expect(editor.history.canUndo, isFalse);

      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();

      expect(editor.textEdit.session, isNull);
    });

    testWidgets('the edit is already committed when the press reaches the '
        'canvas', (tester) async {
      final rect = _rectangle(const Offset(100, 100));
      EditorContext? editor;
      final sessionsAtPress = <TextEditSession?>[];
      editor = await _pumpEditor(
        tester,
        document: Document.fromFeatures([rect]),
        editing: rect,
        // Below the text edit overlay, like the canvas, and above the tools.
        underlay: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => sessionsAtPress.add(editor!.textEdit.session),
        ),
      );

      await tester.tapAt(const Offset(600, 400));

      expect(sessionsAtPress, [null]);
    });

    testWidgets('a press claimed by a widget above the canvas is left alone', (
      tester,
    ) async {
      final claims = PointerClaims();
      final rect = _rectangle(const Offset(100, 100));
      final editor = await _pumpEditor(
        tester,
        document: Document.fromFeatures([rect]),
        claims: claims,
        overlay: Positioned(
          left: 500,
          top: 300,
          width: 200,
          height: 100,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: claims.claim,
          ),
        ),
      );
      editor.startTextEdit(EditTextEditSession.forFeature(rect));

      final gesture = await tester.startGesture(const Offset(550, 350));
      await gesture.moveTo(const Offset(900, 350));
      await gesture.up();
      await tester.pumpAndSettle();

      // Not committed by the press, and released again at pointer-up.
      expect(editor.textEdit.session, isNotNull);
    });

    testWidgets('dragging the shape commits first, then moves it', (
      tester,
    ) async {
      final (editor, rect) = await pumpEditing(tester);

      await tester.dragFrom(const Offset(110, 110), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(editor.textEdit.session, isNull);
      expect((rect.kind as FeatureKindRectangle).label, 'typed');
      expect(rect.origin, const Offset(300, 100));
    });
  });
}

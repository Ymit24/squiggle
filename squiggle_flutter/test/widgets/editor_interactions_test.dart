import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/editor_interactions.dart';

Future<EditorContext> _pumpEditor(
  WidgetTester tester, {
  Document? document,
}) async {
  final editor = EditorContext(document: document ?? Document());
  final canvasKey = GlobalKey();
  final images = ImageRepository();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    images.dispose();
    editor.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: SquiggleThemeData.dark(),
      home: BlocProvider(
        create: (_) => TextEditBloc(context: editor),
        child: EditorInteractions(
          context: editor,
          canvasKey: canvasKey,
          imageRepository: images,
          canvasInteractionsEnabled: true,
          child: SizedBox.expand(key: canvasKey),
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
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(editor.document.nodeById(target.id), isNull);
    expect(editor.document.nodeById(original.id), same(original));
    expect(editor.document.nodeById(underneath.id), same(underneath));
    editor.undo();
    expect(editor.document.nodeById(target.id), isNotNull);
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
}

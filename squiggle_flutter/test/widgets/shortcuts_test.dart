import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  testWidgets('ToolShortcuts activates tools on V, R, C, L, T and 1-5 keys', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(value: ImageRepository()),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ToolbarBloc(context: context)),
                BlocProvider(create: (_) => EditorBloc(context: context)),
              ],
              child: ToolShortcuts(child: const SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toolbarBloc = tester
        .element(find.byType(ToolShortcuts))
        .read<ToolbarBloc>();

    Future<void> pressKey(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key, platform: 'macos');
      await tester.pump();
    }

    await pressKey(LogicalKeyboardKey.keyR);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createRect);

    await pressKey(LogicalKeyboardKey.keyC);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createCircle);

    await pressKey(LogicalKeyboardKey.keyL);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createLine);

    await pressKey(LogicalKeyboardKey.keyT);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createText);

    await pressKey(LogicalKeyboardKey.keyV);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.select);

    await pressKey(LogicalKeyboardKey.digit1);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.select);

    await pressKey(LogicalKeyboardKey.digit2);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createRect);

    await pressKey(LogicalKeyboardKey.digit3);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createCircle);

    await pressKey(LogicalKeyboardKey.digit4);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createLine);

    await pressKey(LogicalKeyboardKey.digit5);
    expect(toolbarBloc.state.activeTool, ActiveToolKind.createText);
  });

  testWidgets('ToolShortcuts deletes selected features on backspace', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );
    final featureId = context.document.features.first.id;
    context.selection.selectFeature(featureId);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(value: ImageRepository()),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ToolbarBloc(context: context)),
                BlocProvider(create: (_) => EditorBloc(context: context)),
              ],
              child: ToolShortcuts(child: const SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace, platform: 'macos');
    await tester.pump();

    expect(context.document.features, isEmpty);
    expect(context.selection.selectedFeatures, isEmpty);
  });

  testWidgets('ToolShortcuts undoes and redoes document commands', (
    tester,
  ) async {
    final context = EditorContext(document: Document());

    context.execute(
      AddFeatureCommand(
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(value: ImageRepository()),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ToolbarBloc(context: context)),
                BlocProvider(create: (_) => EditorBloc(context: context)),
              ],
              child: ToolShortcuts(child: const SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.pump();
    expect(context.document.features, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.pump();
    expect(context.document.features, hasLength(1));
  });

  testWidgets('ToolShortcuts preserves selection when undoing a move', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );
    final feature = context.document.features.first;
    context.selection.selectFeature(feature.id);
    context.execute(
      MoveFeatureCommand(
        feature.id,
        const Offset(40, 40),
        previousOrigin: Offset.zero,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(value: ImageRepository()),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ToolbarBloc(context: context)),
                BlocProvider(create: (_) => EditorBloc(context: context)),
              ],
              child: ToolShortcuts(child: const SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.pump();

    expect(feature.origin, Offset.zero);
    expect(context.selection.selectedFeatures, [feature.id]);
  });

  testWidgets('ToolShortcuts restores focus after text edit closes', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );
    final textFocusNode = FocusNode();

    Future<void> pumpShortcuts({required bool textEditOpen}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<EditorContext>.value(value: context),
                RepositoryProvider<ImageRepository>.value(value: ImageRepository()),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => ToolbarBloc(context: context)),
                  BlocProvider(create: (_) => EditorBloc(context: context)),
                ],
                child: ToolShortcuts(
                  textEditOpen: textEditOpen,
                  child: textEditOpen
                      ? TextField(focusNode: textFocusNode)
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpShortcuts(textEditOpen: true);
    textFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textFocusNode.hasFocus, isTrue);

    await pumpShortcuts(textEditOpen: false);
    expect(textFocusNode.hasFocus, isFalse);

    final toolbarBloc = tester
        .element(find.byType(ToolShortcuts))
        .read<ToolbarBloc>();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV, platform: 'macos');
    await tester.pump();

    expect(toolbarBloc.state.activeTool, ActiveToolKind.select);
  });
}

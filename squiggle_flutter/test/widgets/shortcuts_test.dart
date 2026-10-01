import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
  });

  testWidgets(
    'layer order shortcuts move selection and stay off during text edit',
    (tester) async {
      final context = EditorContext(
        document: Document.fromFeatures([
          for (var i = 0; i < 3; i++)
            Feature(
              origin: Offset(i * 10.0, 0),
              size: const Size(10, 10),
              kind: FeatureKindRectangle(),
            ),
        ]),
      );
      addTearDown(context.dispose);
      final original = context.document.nodes.map((node) => node.id).toList();
      context.selection.setSelection([original[1]]);

      Future<void> pumpShortcuts({bool textEditOpen = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<EditorContext>.value(value: context),
                  RepositoryProvider<ImageRepository>.value(
                    value: ImageRepository(),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => ToolbarBloc(context: context)),
                    BlocProvider(create: (_) => EditorBloc(context: context)),
                  ],
                  child: ToolShortcuts(
                    textEditOpen: textEditOpen,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> pressOrderKey(
        LogicalKeyboardKey modifier,
        LogicalKeyboardKey key, {
        bool alt = false,
      }) async {
        await tester.sendKeyDownEvent(modifier, platform: 'macos');
        if (alt) {
          await tester.sendKeyDownEvent(
            LogicalKeyboardKey.alt,
            platform: 'macos',
          );
        }
        await tester.sendKeyEvent(key, platform: 'macos');
        if (alt) {
          await tester.sendKeyUpEvent(
            LogicalKeyboardKey.alt,
            platform: 'macos',
          );
        }
        await tester.sendKeyUpEvent(modifier, platform: 'macos');
        await tester.pump();
      }

      List<NodeId> currentOrder() =>
          context.document.nodes.map((node) => node.id).toList();

      await pumpShortcuts();
      await pressOrderKey(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.bracketRight,
      );
      expect(currentOrder(), [original[0], original[2], original[1]]);
      await pressOrderKey(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.bracketLeft,
      );
      expect(currentOrder(), original);
      await pressOrderKey(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.bracketLeft,
        alt: true,
      );
      expect(currentOrder(), [original[1], original[0], original[2]]);
      await pressOrderKey(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.bracketRight,
        alt: true,
      );
      expect(currentOrder(), [original[0], original[2], original[1]]);

      await pumpShortcuts(textEditOpen: true);
      await pressOrderKey(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.bracketLeft,
      );
      expect(currentOrder(), [original[0], original[2], original[1]]);
    },
  );

  testWidgets('ToolShortcuts activates tools on V, R, C, L, T and 1-5 keys', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(
                value: ImageRepository(),
              ),
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

    Future<void> pressKey(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key, platform: 'macos');
      await tester.pump();
    }

    await pressKey(LogicalKeyboardKey.keyR);
    expect(context.tool.activeTool, isA<CreateFeatureTool>());
    expect(
      (context.tool.activeTool as CreateFeatureTool).kind,
      isA<FeatureKindRectangle>(),
    );

    await pressKey(LogicalKeyboardKey.keyC);
    expect(context.tool.activeTool, isA<CreateFeatureTool>());
    expect(
      (context.tool.activeTool as CreateFeatureTool).kind,
      isA<FeatureKindCircle>(),
    );

    await pressKey(LogicalKeyboardKey.keyL);
    expect(context.tool.activeTool, isA<CreateLineTool>());

    await pressKey(LogicalKeyboardKey.keyT);
    expect(context.tool.activeTool, isA<CreateTextTool>());

    await pressKey(LogicalKeyboardKey.keyV);
    expect(context.tool.activeTool, isA<SelectTool>());

    await pressKey(LogicalKeyboardKey.digit1);
    expect(context.tool.activeTool, isA<SelectTool>());

    await pressKey(LogicalKeyboardKey.digit2);
    expect(context.tool.activeTool, isA<CreateFeatureTool>());
    expect(
      (context.tool.activeTool as CreateFeatureTool).kind,
      isA<FeatureKindRectangle>(),
    );

    await pressKey(LogicalKeyboardKey.digit3);
    expect(context.tool.activeTool, isA<CreateFeatureTool>());
    expect(
      (context.tool.activeTool as CreateFeatureTool).kind,
      isA<FeatureKindCircle>(),
    );

    await pressKey(LogicalKeyboardKey.digit4);
    expect(context.tool.activeTool, isA<CreateLineTool>());

    await pressKey(LogicalKeyboardKey.digit5);
    expect(context.tool.activeTool, isA<CreateTextTool>());
  });

  testWidgets('ToolShortcuts deletes selected features on backspace', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      ]),
    );
    final featureId = context.document.nodes.first.id;
    context.selection.selectNode(featureId);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(
                value: ImageRepository(),
              ),
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

    expect(context.document.nodes, isEmpty);
    expect(context.selection.selectedNodeIds, isEmpty);
  });

  testWidgets('ToolShortcuts undoes and redoes document commands', (
    tester,
  ) async {
    final context = EditorContext(document: Document());

    context.history.run('Add feature', (transaction) {
      transaction.add(
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(
                value: ImageRepository(),
              ),
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
    expect(context.document.nodes, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.pump();
    expect(context.document.nodes, hasLength(1));
  });

  testWidgets('ToolShortcuts preserves selection when undoing a move', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      ]),
    );
    final feature = context.document.nodes.first;
    context.selection.selectNode(feature.id);
    context.history.run('Move Feature', (transaction) {
      transaction.watch([feature]);
      feature.origin = const Offset(40, 40);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<EditorContext>.value(value: context),
              RepositoryProvider<ImageRepository>.value(
                value: ImageRepository(),
              ),
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
    expect(context.selection.selectedNodeIds, [feature.id]);
  });

  testWidgets('ToolShortcuts restores focus after text edit closes', (
    tester,
  ) async {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
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
                RepositoryProvider<ImageRepository>.value(
                  value: ImageRepository(),
                ),
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

    await tester.sendKeyEvent(LogicalKeyboardKey.keyV, platform: 'macos');
    await tester.pump();

    expect(context.tool.activeTool, isA<SelectTool>());
  });
}

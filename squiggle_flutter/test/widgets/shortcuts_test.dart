import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';

void main() {
  testWidgets('ToolShortcuts activates tools on V, R, C, L, T and 1-5 keys', (
    tester,
  ) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
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
              RepositoryProvider<ToolRepository>.value(value: toolRepository),
              RepositoryProvider<DocumentRepository>.value(
                value: documentRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ToolbarBloc(
                    toolRepository: toolRepository,
                    selectionRepository: selectionRepository,
                    documentRepository: documentRepository,
                  ),
                ),
                BlocProvider(
                  create: (_) => EditorBloc(
                    documentRepository: documentRepository,
                    selectionRepository: selectionRepository,
                    toolRepository: toolRepository,
                  ),
                ),
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
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );
    final featureId = documentRepository.document.features.first.id;
    selectionRepository.selectFeature(featureId);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ToolRepository>.value(value: toolRepository),
              RepositoryProvider<DocumentRepository>.value(
                value: documentRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ToolbarBloc(
                    toolRepository: toolRepository,
                    selectionRepository: selectionRepository,
                    documentRepository: documentRepository,
                  ),
                ),
                BlocProvider(
                  create: (_) => EditorBloc(
                    documentRepository: documentRepository,
                    selectionRepository: selectionRepository,
                    toolRepository: toolRepository,
                  ),
                ),
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

    expect(documentRepository.document.features, isEmpty);
    expect(selectionRepository.selectedFeatures, isEmpty);
  });

  testWidgets('ToolShortcuts undoes and redoes document commands', (
    tester,
  ) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(document: Document());

    documentRepository.executeCommand(
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
              RepositoryProvider<ToolRepository>.value(value: toolRepository),
              RepositoryProvider<DocumentRepository>.value(
                value: documentRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ToolbarBloc(
                    toolRepository: toolRepository,
                    selectionRepository: selectionRepository,
                    documentRepository: documentRepository,
                  ),
                ),
                BlocProvider(
                  create: (_) => EditorBloc(
                    documentRepository: documentRepository,
                    selectionRepository: selectionRepository,
                    toolRepository: toolRepository,
                  ),
                ),
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
    expect(documentRepository.document.features, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift, platform: 'macos');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
    await tester.pump();
    expect(documentRepository.document.features, hasLength(1));
  });

  testWidgets('ToolShortcuts preserves selection when undoing a move', (
    tester,
  ) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]),
    );
    final feature = documentRepository.document.features.first;
    selectionRepository.selectFeature(feature.id);
    documentRepository.executeCommand(
      MoveFeatureCommand(feature.id, const Offset(40, 40)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ToolRepository>.value(value: toolRepository),
              RepositoryProvider<DocumentRepository>.value(
                value: documentRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ToolbarBloc(
                    toolRepository: toolRepository,
                    selectionRepository: selectionRepository,
                    documentRepository: documentRepository,
                  ),
                ),
                BlocProvider(
                  create: (_) => EditorBloc(
                    documentRepository: documentRepository,
                    selectionRepository: selectionRepository,
                    toolRepository: toolRepository,
                  ),
                ),
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
    expect(selectionRepository.selectedFeatures, [feature.id]);
  });

  testWidgets('ToolShortcuts restores focus after text edit closes', (
    tester,
  ) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
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
                RepositoryProvider<ToolRepository>.value(value: toolRepository),
                RepositoryProvider<DocumentRepository>.value(
                  value: documentRepository,
                ),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => ToolbarBloc(
                      toolRepository: toolRepository,
                      selectionRepository: selectionRepository,
                      documentRepository: documentRepository,
                    ),
                  ),
                  BlocProvider(
                    create: (_) => EditorBloc(
                      documentRepository: documentRepository,
                      selectionRepository: selectionRepository,
                      toolRepository: toolRepository,
                    ),
                  ),
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

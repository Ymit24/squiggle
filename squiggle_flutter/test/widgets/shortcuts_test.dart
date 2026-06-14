import 'dart:ui';

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
  testWidgets('ToolShortcuts activates tools on V, R, C keys', (tester) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
      document: Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(100, 100)),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => ToolbarBloc(
                  toolRepository: toolRepository,
                  selectionRepository: selectionRepository,
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
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toolbarBloc =
        tester.element(find.byType(ToolShortcuts)).read<ToolbarBloc>();

    Future<void> pressKey(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key, platform: 'macos');
      await tester.pump();
    }

    await pressKey(LogicalKeyboardKey.keyR);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.createRect,
    );

    await pressKey(LogicalKeyboardKey.keyC);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.createCircle,
    );

    await pressKey(LogicalKeyboardKey.keyV);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.select,
    );
  });

  testWidgets('ToolShortcuts deletes selected features on backspace', (
    tester,
  ) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();
    final documentRepository = DocumentRepository(
      document: Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(100, 100)),
      ]),
    );
    final featureId = documentRepository.document.features.first.id;
    selectionRepository.selectFeature(featureId);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => ToolbarBloc(
                  toolRepository: toolRepository,
                  selectionRepository: selectionRepository,
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
              child: const SizedBox.expand(),
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
}

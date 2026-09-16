import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/document_library_page.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentLibraryPage window sizes', () {
    late Directory tempDir;
    late ImageRepository imageRepository;
    late DocumentStorage documentStorage;
    late EditorContext editorContext;
    late DocumentLibraryRepository library;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_page_');
      imageRepository = ImageRepository(
        imagesDirectory: Directory('${tempDir.path}/images'),
      );
      await imageRepository.initialize();
      documentStorage = DocumentStorage(
        imageRepository: imageRepository,
        storageDirectory: tempDir,
      );
      editorContext = EditorContext(document: Document());
      library = DocumentLibraryRepository(
        documentStorage: documentStorage,
        context: editorContext,
      );
      await library.initialize();
      await library.createDocument(name: 'Second');
    });

    tearDown(() async {
      library.dispose();
      editorContext.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> pumpLibraryPage(
      WidgetTester tester, {
      Future<void> Function(String id)? onOpenDocument,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: RepositoryProvider<ImageRepository>.value(
            value: imageRepository,
            child: RepositoryProvider<DocumentStorage>.value(
              value: documentStorage,
              child: RepositoryProvider<DocumentLibraryRepository>.value(
                value: library,
                child: DocumentLibraryPage(
                  onOpenDocument: onOpenDocument ?? (_) async {},
                  onCreateAndOpen: ({String? name}) async {},
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('minimum 640x480 uses compact layout without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLibraryPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('All canvases'), findsOneWidget);
      expect(find.text('Documents'), findsNothing);
      expect(find.text('Recent'), findsNothing);
      expect(find.byTooltip('New canvas'), findsOneWidget);
      expect(find.byTooltip('Sort canvases'), findsOneWidget);
    });

    testWidgets('wide window uses full layout without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLibraryPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('All canvases'), findsOneWidget);
      expect(find.text('Documents'), findsNothing);
      expect(find.text('Recent'), findsOneWidget);

      final searchSize = tester.getSize(
        find.byKey(const ValueKey('library-search')),
      );
      final sortSize = tester.getSize(
        find.byKey(const ValueKey('library-sort')),
      );
      final newSize = tester.getSize(find.byKey(const ValueKey('library-new')));
      expect(sortSize.height, searchSize.height);
      expect(newSize.height, searchSize.height);
      expect(find.byKey(const ValueKey('library-featured-card')), findsNothing);
    });

    testWidgets('Cmd+/ focuses search after clicking the page body', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> focusSearchWithShortcut() async {
        await tester.sendKeyDownEvent(
          LogicalKeyboardKey.meta,
          platform: 'macos',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.slash, platform: 'macos');
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta, platform: 'macos');
        await tester.pump();
      }

      await pumpLibraryPage(tester);
      final search = tester.widget<TextField>(find.byType(TextField));

      await tester.tap(find.text('All canvases'));
      await focusSearchWithShortcut();
      expect(search.focusNode?.hasFocus, isTrue);

      await tester.tap(find.text('All canvases'));
      await tester.pump();
      expect(search.focusNode?.hasFocus, isFalse);

      await focusSearchWithShortcut();
      expect(search.focusNode?.hasFocus, isTrue);
    });

    testWidgets('sort menu opens below its anchor', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLibraryPage(tester);

      final sortButton = find.byKey(const ValueKey('library-sort'));
      await tester.tap(sortButton);
      await tester.pump(const Duration(milliseconds: 300));

      final firstMenuItem = find.ancestor(
        of: find.text('Last edited'),
        matching: find.byType(MenuItemButton),
      );
      expect(firstMenuItem, findsOneWidget);
      expect(
        tester.getTopLeft(firstMenuItem).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(sortButton).dy),
      );
    });

    testWidgets('card menu does not trigger the card action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var openCount = 0;
      await pumpLibraryPage(tester, onOpenDocument: (_) async => openCount++);

      final cardMenu = find.byTooltip('Document actions').first;
      final center = tester.getCenter(cardMenu);
      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(center);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(find.text('Rename'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      expect(openCount, 0);
      expect(find.text('Rename'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(find.text('Rename'), findsNothing);
    });
  });
}

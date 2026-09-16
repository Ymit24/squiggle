import 'dart:io';

import 'package:flutter/material.dart';
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
      // Two documents so the featured card renders too.
      await library.createDocument(name: 'Second');
    });

    tearDown(() async {
      library.dispose();
      editorContext.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> pumpLibraryPage(WidgetTester tester) async {
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
                  onOpenDocument: (_) async {},
                  onCreateAndOpen: ({String? name}) async {},
                ),
              ),
            ),
          ),
        ),
      );
      // Manual pumps instead of pumpAndSettle: thumbnail placeholders
      // run a repeating shimmer while loads are pending, which never
      // settles by design.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('minimum 640x480 uses compact layout without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(640, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLibraryPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Your documents'), findsOneWidget);
      // Compact header: icon-only actions, labels hidden.
      expect(find.text('Recent'), findsNothing);
      expect(find.byTooltip('New canvas'), findsOneWidget);
      expect(find.byTooltip('Sort canvases'), findsOneWidget);
    });

    testWidgets('wide window uses full layout without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLibraryPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Your documents'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
    });
  });
}

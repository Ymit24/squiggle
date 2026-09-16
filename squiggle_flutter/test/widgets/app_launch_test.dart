import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/main.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  testWidgets('launches with EditorContext provided as a ChangeNotifier', (
    tester,
  ) async {
    final imageRepository = ImageRepository();
    final editorContext = EditorContext(document: Document());
    final documentStorage = DocumentStorage(imageRepository: imageRepository);
    final documentLibraryRepository = DocumentLibraryRepository(
      documentStorage: documentStorage,
      context: editorContext,
    );
    addTearDown(editorContext.dispose);

    await tester.pumpWidget(
      SquiggleApp(
        imageRepository: imageRepository,
        context: editorContext,
        documentStorage: documentStorage,
        documentLibraryRepository: documentLibraryRepository,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Your documents'), findsOneWidget);
  });
}

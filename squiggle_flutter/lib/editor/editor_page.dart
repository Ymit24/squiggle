import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';

@RoutePage(name: "EditorRoute")
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final editorContext = context.read<EditorContext>();
    return Editor(
      editorContext: editorContext,
      onBackToLibrary: () => _returnToLibrary(context),
    );
  }

  Future<void> _returnToLibrary(BuildContext context) async {
    final library = context.read<DocumentLibraryRepository>();
    await library.saveCurrentDocument();
    await library.refreshDocuments();

    if (!context.mounted) return;
    await context.router.replace(DocumentLibraryRoute());
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';

@RoutePage(name: "EditorRoute")
class EditorPage extends StatefulWidget {
  const EditorPage({super.key, @PathParam("id") required this.id});

  final String id;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late Future<void> _loadCallback;

  @override
  void initState() {
    super.initState();

    final library = context.read<DocumentLibraryRepository>();
    _loadCallback = library.openDocument(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final editorContext = context.read<EditorContext>();
    return Scaffold(
      body: FutureBuilder(
        future: _loadCallback,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.hasError ||
              asyncSnapshot.connectionState != ConnectionState.done) {
            return SizedBox.shrink();
          }

          return Editor(
            editorContext: editorContext,
            onBackToLibrary: () => _returnToLibrary(context),
          );
        },
      ),
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

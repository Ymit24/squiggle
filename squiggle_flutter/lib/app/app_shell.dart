import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/document_library_page.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';

enum _AppScreen { library, editor }

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.context});

  final EditorContext context;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppScreen _screen = _AppScreen.library;

  Future<void> _openDocument(String id) async {
    final library = context.read<DocumentLibraryRepository>();
    await library.openDocument(id);
    if (!mounted) return;
    setState(() => _screen = _AppScreen.editor);
  }

  Future<void> _createAndOpen({String? name}) async {
    final library = context.read<DocumentLibraryRepository>();
    await library.createDocument(name: name);
    if (!mounted) return;
    setState(() => _screen = _AppScreen.editor);
  }

  Future<void> _returnToLibrary() async {
    final library = context.read<DocumentLibraryRepository>();
    await library.saveCurrentDocument();
    await library.refreshDocuments();
    if (!mounted) return;
    setState(() => _screen = _AppScreen.library);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      _AppScreen.library => DocumentLibraryPage(
        onOpenDocument: _openDocument,
        onCreateAndOpen: _createAndOpen,
      ),
      _AppScreen.editor => Editor(
        editorContext: widget.context,
        onBackToLibrary: _returnToLibrary,
      ),
    };
  }
}

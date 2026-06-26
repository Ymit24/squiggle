import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/document_library_page.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum _AppScreen { library, editor }

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.documentRepository});

  final DocumentRepository documentRepository;

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
        documentRepository: widget.documentRepository,
        onBackToLibrary: _returnToLibrary,
      ),
    };
  }
}

/// Back control shown while editing a document.
class EditorBackButton extends StatefulWidget {
  const EditorBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<EditorBackButton> createState() => _EditorBackButtonState();
}

class _EditorBackButtonState extends State<EditorBackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hovering
                ? colors.surface0.withValues(alpha: 0.85)
                : colors.mantle,
            border: Border.all(color: colors.surface1),
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: _hovering ? colors.text : colors.subtext0,
                ),
                const SizedBox(width: 8),
                Text(
                  'All documents',
                    style: theme.typography.inputText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _hovering ? colors.text : colors.subtext0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

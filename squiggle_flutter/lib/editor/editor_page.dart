import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/widgets/save_failed_dialog.dart';
import 'package:squiggle_flutter/editor/widgets/unreadable_document_view.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';

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

    final activeDocument = context.read<ActiveDocumentCoordinator>();
    _loadCallback = activeDocument.openDocument(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final editorContext = context.read<EditorContext>();
    return Scaffold(
      body: FutureBuilder(
        future: _loadCallback,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState != ConnectionState.done) {
            return SizedBox.shrink();
          }

          if (asyncSnapshot.hasError) {
            return UnreadableDocumentView(
              onBackToLibrary: () => _returnToLibrary(context),
              message: UnreadableDocumentView.failedMessage,
            );
          }

          final loadError = context.read<ActiveDocumentCoordinator>().loadError;
          if (loadError != null) {
            return UnreadableDocumentView(
              onBackToLibrary: () => _returnToLibrary(context),
              message: loadError is DocumentNotFoundException
                  ? UnreadableDocumentView.missingMessage
                  : UnreadableDocumentView.unreadableMessage,
            );
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
    final activeDocument = context.read<ActiveDocumentCoordinator>();
    final documentList = context.read<DocumentListNotifier>();
    try {
      await activeDocument.flush();
    } on DocumentSaveException {
      if (!context.mounted) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => const SaveFailedDialog(),
      );
      if (leave != true) return;
      activeDocument.discardActiveDocument();
    }
    await documentList.refresh();

    if (!context.mounted) return;
    await context.router.replace(DocumentLibraryRoute());
  }
}

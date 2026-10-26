import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview_placeholder.dart';
import 'package:squiggle_flutter/document_library/widgets/empty_document_preview_glyph.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

class DocumentPreviewLoader extends StatefulWidget {
  const DocumentPreviewLoader({super.key, required this.document});

  final DocumentInfo document;

  @override
  State<DocumentPreviewLoader> createState() => _DocumentPreviewLoaderState();
}

class _DocumentPreviewLoaderState extends State<DocumentPreviewLoader> {
  late Future<List<Node>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.document.id);
  }

  @override
  void didUpdateWidget(DocumentPreviewLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document.id != oldWidget.document.id ||
        widget.document.updatedAt != oldWidget.document.updatedAt) {
      _future = _load(widget.document.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageRepository = context.read<ImageRepository>();

    return FutureBuilder<List<Node>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DocumentPreviewPlaceholder();
        }
        final nodes = snapshot.data ?? const [];
        if (nodes.isEmpty) {
          return Stack(
            children: [
              DocumentPreview(
                nodes: const [],
                imageRepository: imageRepository,
              ),
              const Center(child: EmptyDocumentPreviewGlyph()),
            ],
          );
        }
        return DocumentPreview(nodes: nodes, imageRepository: imageRepository);
      },
    );
  }

  Future<List<Node>> _load(String documentId) {
    final documents = context.read<DocumentsDao>();
    return _loadPreviewNodes(documents, documentId);
  }
}

/// The nodes to draw as a preview; empty if the document cannot be read.
Future<List<Node>> _loadPreviewNodes(
  DocumentsDao documents,
  String documentId,
) async {
  try {
    final stored = await documents.load(documentId);
    return stored == null ? const [] : Document.fromDataModel(stored).nodes;
  } on Object {
    return const [];
  }
}

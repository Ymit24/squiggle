import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

/// Loads persisted nodes and renders an accurate document thumbnail.
class DocumentPreviewLoader extends StatelessWidget {
  const DocumentPreviewLoader({super.key, required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final storage = context.read<DocumentStorage>();
    final imageRepository = context.read<ImageRepository>();
    final cacheKey =
        '${document.id}-${document.updatedAt.millisecondsSinceEpoch}-${document.featureCount}';

    return FutureBuilder<List<Node>>(
      key: ValueKey(cacheKey),
      future: _loadNodes(storage, document),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(color: Color(0xFF1E1E2E));
        }

        return Placeholder(
          child: DocumentPreview(
            nodes: snapshot.data ?? const [],
            imageRepository: imageRepository,
          ),
        );
      },
    );
  }

  static Future<List<Node>> _loadNodes(
    DocumentStorage storage,
    DocumentInfo document,
  ) async {
    final decoded = await storage.loadDocument(document.id);
    return decoded?.document.nodes ?? const [];
  }
}

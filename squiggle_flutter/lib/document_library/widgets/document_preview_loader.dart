import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

/// Loads persisted features and renders an accurate document thumbnail.
class DocumentPreviewLoader extends StatelessWidget {
  const DocumentPreviewLoader({super.key, required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final storage = context.read<DocumentStorage>();
    final imageRepository = context.read<ImageRepository>();
    final cacheKey =
        '${document.id}-${document.updatedAt.millisecondsSinceEpoch}-${document.featureCount}';

    return FutureBuilder<List<Feature>>(
      key: ValueKey(cacheKey),
      future: _loadFeatures(storage, document),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(color: Color(0xFF1E1E2E));
        }

        return DocumentPreview(
          features: snapshot.data ?? const [],
          imageRepository: imageRepository,
        );
      },
    );
  }

  static Future<List<Feature>> _loadFeatures(
    DocumentStorage storage,
    DocumentInfo document,
  ) async {
    final decoded = await storage.loadDocument(document.id);
    return decoded?.document.features ?? const [];
  }
}

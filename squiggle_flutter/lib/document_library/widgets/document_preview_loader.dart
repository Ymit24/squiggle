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
        '${document.id}-${document.updatedAt.millisecondsSinceEpoch}';

    return FutureBuilder<List<Node>>(
      key: ValueKey(cacheKey),
      future: loadPreviewNodes(storage, document.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PreviewPlaceholder();
        }
        final nodes = snapshot.data ?? const [];
        if (nodes.isEmpty) {
          return Stack(
            children: [
              DocumentPreview(
                nodes: const [],
                imageRepository: imageRepository,
              ),
              const Center(child: _EmptyGlyph()),
            ],
          );
        }
        return DocumentPreview(
          nodes: nodes,
          imageRepository: imageRepository,
        );
      },
    );
  }
}

/// Shared node fetch for thumbnails so cards don't each invent caching.
Future<List<Node>> loadPreviewNodes(
  DocumentStorage storage,
  String documentId,
) async {
  final decoded = await storage.loadDocument(documentId);
  return decoded?.document.nodes ?? const [];
}

class _PreviewPlaceholder extends StatefulWidget {
  const _PreviewPlaceholder();

  @override
  State<_PreviewPlaceholder> createState() => _PreviewPlaceholderState();
}

class _PreviewPlaceholderState extends State<_PreviewPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ColoredBox(
            color: Color.lerp(
              const Color(0xFF1D1D24),
              const Color(0xFF242430),
              _controller.value,
            )!,
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _EmptyGlyph extends StatelessWidget {
  const _EmptyGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E3E4D)),
      ),
      child: const Icon(
        Icons.crop_square_rounded,
        size: 20,
        color: Color(0xFF8E8EA3),
      ),
    );
  }
}

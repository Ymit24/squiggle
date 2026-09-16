import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
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

  Future<List<Node>> _load(String documentId) {
    final storage = context.read<DocumentStorage>();
    return _loadPreviewNodes(storage, documentId);
  }

  @override
  Widget build(BuildContext context) {
    final imageRepository = context.read<ImageRepository>();

    return FutureBuilder<List<Node>>(
      future: _future,
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
        return DocumentPreview(nodes: nodes, imageRepository: imageRepository);
      },
    );
  }
}

Future<List<Node>> _loadPreviewNodes(
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

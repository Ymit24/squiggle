import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import '../theme/squiggle_colors.dart';
import 'document_canvas.dart';
import 'viewport_tool_cursor.dart';
import 'editor_interactions.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({
    super.key,
    required this.context,
    required this.imageRepository,
  });

  final EditorContext context;
  final ImageRepository imageRepository;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport>
    with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextEditBloc, TextEditState>(
      builder: (context, textEditState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            widget.context.viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return EditorInteractions(
              context: widget.context,
              canvasKey: _canvasKey,
              imageRepository: widget.imageRepository,
              canvasInteractionsEnabled: textEditState is! TextEditOpen,
              child: Container(
                key: _viewportKey,
                color: SquiggleColors.base,
                child: ViewportToolCursor(
                  context: widget.context,
                  canvasKey: _canvasKey,
                  child: DocumentCanvas(
                    key: _canvasKey,
                    context: widget.context,
                    imageRepository: widget.imageRepository,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

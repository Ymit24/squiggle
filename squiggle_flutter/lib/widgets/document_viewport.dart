import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/widgets/document_canvas.dart';
import 'package:squiggle_flutter/widgets/viewport_tool_cursor.dart';
import 'package:squiggle_flutter/widgets/editor_interactions.dart';

/// Full-area viewport with scroll/pinch pan and zoom over a [DocumentCanvas].
class DocumentViewport extends StatefulWidget {
  const DocumentViewport({
    super.key,
    required this.editorContext,
    required this.imageRepository,
  });

  final EditorContext editorContext;
  final ImageRepository imageRepository;

  @override
  State<DocumentViewport> createState() => _DocumentViewportState();
}

class _DocumentViewportState extends State<DocumentViewport> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextEditBloc, TextEditState>(
      builder: (context, textEditState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            widget.editorContext.viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return EditorInteractions(
              context: widget.editorContext,
              canvasKey: _canvasKey,
              imageRepository: widget.imageRepository,
              canvasInteractionsEnabled: textEditState is! TextEditOpen,
              child: Container(
                color: SquiggleColors.base,
                child: ViewportToolCursor(
                  context: widget.editorContext,
                  canvasKey: _canvasKey,
                  child: DocumentCanvas(
                    key: _canvasKey,
                    context: widget.editorContext,
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

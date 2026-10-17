import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/widgets/document_canvas.dart';
import 'package:squiggle_flutter/editor/widgets/editor_interactions.dart';
import 'package:squiggle_flutter/editor/widgets/pointer_claims.dart';
import 'package:squiggle_flutter/editor/widgets/viewport_tool_cursor.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

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
  final _pointerClaims = PointerClaims();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.editorContext.textEdit,
      builder: (context, _) {
        final session = widget.editorContext.textEdit.session;
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
              pointerClaims: _pointerClaims,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
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
                  if (session != null)
                    TextEditOverlay(
                      key: ObjectKey(session),
                      session: session,
                      pointerClaims: _pointerClaims,
                      editorContext: widget.editorContext,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

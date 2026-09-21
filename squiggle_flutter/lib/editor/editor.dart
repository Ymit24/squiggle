import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/inspector_panel.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/editor/widgets/back_to_content.dart';
import 'package:squiggle_flutter/editor/widgets/editor_back_button.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';

class Editor extends StatelessWidget {
  const Editor({
    super.key,
    required this.editorContext,
    required this.onBackToLibrary,
  });

  final EditorContext editorContext;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final imageRepository = context.read<ImageRepository>();

    return BlocProvider(
      create: (context) =>
          TextEditBloc(context: editorContext)
            ..add(const RequestWatchTextEditStateEvent()),
      child: BlocProvider(
        create: (context) =>
            EditorBloc(context: editorContext)
              ..add(const RequestWatchEditorStateEvent()),
        child: BlocBuilder<TextEditBloc, TextEditState>(
          builder: (context, textEditState) {
            final textEditOpen = textEditState is TextEditOpen;

            return ToolShortcuts(
              textEditOpen: textEditOpen,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DocumentViewport(
                        editorContext: editorContext,
                        imageRepository: imageRepository,
                      ),
                      Positioned(
                        top: context.squiggleTheme.spacing.overlayTop,
                        bottom: context.squiggleTheme.spacing.overlayTop,
                        left: context.squiggleTheme.spacing.overlaySide,
                        child: Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EditorBackButton(onPressed: onBackToLibrary),
                            Flexible(
                              child: InspectorPanel(
                                editorContext: editorContext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const EditorToolbar(),
                      if (textEditOpen)
                        TextEditOverlay(
                          state: textEditState,
                          viewportSize: viewportSize,
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: context.squiggleTheme.spacing.overlayTop,
                        child: Center(
                          child: BackToContent(editorContext: editorContext),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

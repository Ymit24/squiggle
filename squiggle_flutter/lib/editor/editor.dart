import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_host.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/inspector_panel.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/editor/widgets/back_to_content.dart';
import 'package:squiggle_flutter/editor/widgets/document_viewport.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

@RoutePage(name: "EditorRoute")
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
          EditorBloc(context: editorContext)
            ..add(const RequestWatchEditorStateEvent()),
      child: ListenableBuilder(
        listenable: editorContext.textEdit,
        builder: (context, _) {
          final textEditOpen = editorContext.textEdit.session != null;

          return BrushWheelHost(
            editorContext: editorContext,
            imageRepository: imageRepository,
            textEditOpen: textEditOpen,
            child: ToolShortcuts(
              textEditOpen: textEditOpen,
              child: Stack(
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
                        SquiggleButton(
                          onPressed: onBackToLibrary,
                          icon: Icons.grid_view_rounded,
                          label: 'Canvas library',
                          variant: SquiggleButtonVariant.secondary,
                          compact: true,
                        ),
                        Flexible(
                          child: InspectorPanel(editorContext: editorContext),
                        ),
                      ],
                    ),
                  ),
                  const EditorToolbar(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: context.squiggleTheme.spacing.overlayTop,
                    child: Center(
                      child: BackToContent(editorContext: editorContext),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

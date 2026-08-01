import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/style_panel.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';

class Editor extends StatelessWidget {
  const Editor({
    super.key,
    required this.context,
    required this.onBackToLibrary,
  });

  final EditorContext context;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final imageRepository = context.read<ImageRepository>();

    return BlocProvider(
      create: (context) => StylePanelBloc(
        context: this.context,
      )..add(const RequestWatchStylePanelStateEvent()),
      child: BlocProvider(
        create: (context) => TextEditBloc(
          context: this.context,
        )..add(const RequestWatchTextEditStateEvent()),
        child: BlocProvider(
          create: (context) => EditorBloc(
            context: this.context,
          )..add(const RequestWatchEditorStateEvent()),
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
                          context: this.context,
                          imageRepository: imageRepository,
                        ),
                        const EditorToolbar(),
                        Positioned(
                          top: context.squiggleTheme.spacing.overlayTop,
                          right: context.squiggleTheme.spacing.overlaySide,
                          child: EditorBackButton(onPressed: onBackToLibrary),
                        ),
                        StylePanel(viewportHeight: viewportSize.height),
                        if (textEditOpen)
                          TextEditOverlay(
                            state: textEditState,
                            viewportSize: viewportSize,
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

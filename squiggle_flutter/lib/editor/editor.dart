import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/style_panel.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';

class Editor extends StatelessWidget {
  const Editor({
    super.key,
    required this.documentRepository,
    required this.onBackToLibrary,
  });

  final DocumentRepository documentRepository;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final selectionRepository = context.read<SelectionRepository>();
    final toolRepository = context.read<ToolRepository>();
    final textEditRepository = context.read<TextEditRepository>();
    final imageRepository = context.read<ImageRepository>();
    final viewportRepository = context.read<ViewportRepository>();

    return BlocProvider(
      create: (context) => StylePanelBloc(
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
      )..add(const RequestWatchStylePanelStateEvent()),
      child: BlocProvider(
        create: (context) => TextEditBloc(
          documentRepository: documentRepository,
          textEditRepository: textEditRepository,
        )..add(const RequestWatchTextEditStateEvent()),
        child: BlocProvider(
          create: (context) => EditorBloc(
            documentRepository: documentRepository,
            selectionRepository: selectionRepository,
            toolRepository: toolRepository,
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
                          documentRepository: documentRepository,
                          toolRepository: toolRepository,
                          selectionRepository: selectionRepository,
                          textEditRepository: textEditRepository,
                          imageRepository: imageRepository,
                          viewportRepository: viewportRepository,
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

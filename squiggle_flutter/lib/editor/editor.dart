import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';

class Editor extends StatelessWidget {
  const Editor({super.key, required this.documentRepository});

  final DocumentRepository documentRepository;

  @override
  Widget build(BuildContext context) {
    final selectionRepository = context.read<SelectionRepository>();
    final toolRepository = context.read<ToolRepository>();

    return BlocProvider(
      create: (context) => EditorBloc(
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
        toolRepository: toolRepository,
      )..add(const RequestWatchEditorStateEvent()),
      child: BlocBuilder<EditorBloc, EditorState>(
        buildWhen: (previous, current) =>
            previous.selectedFeatures != current.selectedFeatures,
        builder: (context, state) {
          return EditorShortcuts(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DocumentViewport(
                  documentRepository: documentRepository,
                  toolRepository: toolRepository,
                  selectionRepository: selectionRepository,
                  selectedFeatures: [...state.selectedFeatures],
                ),
                const EditorToolbar(),
              ],
            ),
          );
        },
      ),
    );
  }
}

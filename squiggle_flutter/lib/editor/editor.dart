import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';

class Editor extends StatelessWidget {
  const Editor({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final selectionRepository = context.read<SelectionRepository>();
    return BlocProvider(
      create: (context) => EditorBloc(
        document: document,
        selectionRepository: selectionRepository,
      )..add(SelectFeatureEvent(FeatureId.newId(4))),
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) => DocumentViewport(
          document: document,
          selectedFeatures: [...state.selectedFeatures],
        ),
      ),
    );
  }
}

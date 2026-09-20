import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/inspector_panel.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_overlay.dart';
import 'package:squiggle_flutter/editor/toolbar/toolbar.dart';
import 'package:squiggle_flutter/models/feature.dart';
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
          StylePanelBloc(context: editorContext)
            ..add(const RequestWatchStylePanelStateEvent()),
      child: BlocProvider(
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
                              Expanded(
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

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key, required this.editorContext});

  final EditorContext editorContext;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return ListenableBuilder(
      listenable: Listenable.merge([
        editorContext.selection,
        editorContext.history,
      ]),
      builder: (context, _) {
        final selectedNodes = editorContext.selection.selectedNodeIds
            .map((nodeId) => editorContext.document.requireNodeById(nodeId))
            .whereType<Feature>();
        if (selectedNodes.isEmpty) {
          return SizedBox.shrink();
        }

        final inspectorCapabilityWidgets = buildInspectorPanel(
          context,
          editorContext,
          selectedNodes.toList(),
        );

        print("Building inspector.");

        return DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.panelPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...inspectorCapabilityWidgets
                      .map(
                        (widget) => [
                          widget,
                          SizedBox(height: spacing.panelSectionSpacing),
                        ],
                      )
                      .flattened,
                  // SectionLabel('Stroke'),
                  // ColorRow(
                  //   presets: stylePresets
                  //       .map((preset) => preset.strokeColor)
                  //       .toList(),
                  //   activePresetIndex: state.strokeMixed
                  //       ? null
                  //       : state.activeStrokePresetIndex,
                  //   isNoneActive: state.isStrokeNone,
                  //   noneEnabled: state.canClearStroke,
                  //   onPresetSelected: (index) =>
                  //       bloc.add(SetStrokePresetEvent(index)),
                  //   onNoneSelected: () => bloc.add(const ClearStrokeEvent()),
                  // ),
                  // SizedBox(height: spacing.panelSectionSpacing),
                ],
              ),
            ),
          ),
        );

        // return Column(
        //   children: [
        //     Text("Yo2: selected feature ids: ${selectedNodes.length}"),
        //     ...inspectorCapabilityWidgets,
        //   ],
        // );
      },
    );
  }
}

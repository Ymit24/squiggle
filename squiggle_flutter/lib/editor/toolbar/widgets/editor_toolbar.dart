import 'package:flutter/material.dart' hide Divider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/button.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/divider.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/gap.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Floating toolbar overlay, matching rust-version layout and styling.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final toolModel = context.read<EditorContext>().tool;
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return Positioned(
      top: spacing.overlayTop,
      left: 0,
      right: 0,
      child: Center(
        child: BlocBuilder<ToolbarBloc, ToolbarState>(
          builder: (context, state) {
            return ListenableBuilder(
              listenable: toolModel,
              builder: (context, _) {
                final activeTool = toolModel.activeTool;
                return DecoratedBox(
                  decoration: theme.decorations.floatingPanel(),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.toolbarPadding),
                    child: SizedBox(
                      height: spacing.toolbarButtonSize,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Button(
                            iconAsset: 'assets/icons/arrow_selector_tool.svg',
                            hotkey: '1',
                            isActive: activeTool is SelectTool,
                            onPressed: () => context.read<ToolbarBloc>().add(
                              const ActivateSelectToolEvent(),
                            ),
                          ),
                          const Gap(),
                          const Divider(),
                          const Gap(),
                          Button(
                            iconAsset: 'assets/icons/crop_square.svg',
                            hotkey: '2',
                            isActive:
                                activeTool is CreateFeatureTool &&
                                activeTool.kind is FeatureKindRectangle,
                            onPressed: () => context.read<ToolbarBloc>().add(
                              const ActivateCreateRectToolEvent(),
                            ),
                          ),
                          const Gap(),
                          Button(
                            iconAsset: 'assets/icons/circle.svg',
                            hotkey: '3',
                            isActive:
                                activeTool is CreateFeatureTool &&
                                activeTool.kind is FeatureKindCircle,
                            onPressed: () => context.read<ToolbarBloc>().add(
                              const ActivateCreateCircleToolEvent(),
                            ),
                          ),
                          const Gap(),
                          Button(
                            iconAsset: 'assets/icons/line.svg',
                            hotkey: '4',
                            isActive: activeTool is CreateLineTool,
                            onPressed: () => context.read<ToolbarBloc>().add(
                              const ActivateCreateLineToolEvent(),
                            ),
                          ),
                          const Gap(),
                          Button(
                            label: 'A',
                            hotkey: '5',
                            isActive: activeTool is CreateTextTool,
                            onPressed: () => context.read<ToolbarBloc>().add(
                              const ActivateCreateTextToolEvent(),
                            ),
                          ),
                          const Gap(),
                          const Divider(),
                          const Gap(),
                          Button(
                            icon: Icons.undo,
                            isActive: false,
                            onPressed: state.canUndo
                                ? () => context.read<ToolbarBloc>().add(
                                    const UndoDocumentEvent(),
                                  )
                                : null,
                          ),
                          const Gap(),
                          Button(
                            icon: Icons.redo,
                            isActive: false,
                            onPressed: state.canRedo
                                ? () => context.read<ToolbarBloc>().add(
                                    const RedoDocumentEvent(),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

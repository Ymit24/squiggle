import 'package:flutter/material.dart' hide Divider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/button.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/divider.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/gap.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Floating toolbar overlay, matching rust-version layout and styling.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return Positioned(
      top: spacing.overlayTop,
      left: 0,
      right: 0,
      child: Center(
        child: BlocBuilder<ToolbarBloc, ToolbarState>(
          builder: (context, state) {
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
                        isActive: state.activeTool == ActiveToolKind.select,
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
                        isActive: state.activeTool == ActiveToolKind.createRect,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateRectToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/circle.svg',
                        hotkey: '3',
                        isActive:
                            state.activeTool == ActiveToolKind.createCircle,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateCircleToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/line.svg',
                        hotkey: '4',
                        isActive: state.activeTool == ActiveToolKind.createLine,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateLineToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        label: 'A',
                        hotkey: '5',
                        isActive: state.activeTool == ActiveToolKind.createText,
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
        ),
      ),
    );
  }
}

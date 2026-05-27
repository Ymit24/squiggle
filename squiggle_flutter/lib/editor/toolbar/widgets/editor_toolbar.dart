import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar_button.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar_divider.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar_gap.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar_metrics.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

/// Floating toolbar overlay, matching rust-version layout and styling.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: BlocBuilder<ToolbarBloc, ToolbarState>(
          builder: (context, state) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: SquiggleColors.mantle,
                border: Border.all(color: SquiggleColors.surface1),
                borderRadius: BorderRadius.circular(toolbarOuterRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(toolbarPadding),
                child: SizedBox(
                  height: toolButtonSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ToolbarButton(
                        iconAsset: 'assets/icons/arrow_selector_tool.svg',
                        isActive: state.activeTool == ActiveToolKind.select,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateSelectToolEvent(),
                        ),
                      ),
                      const ToolbarGap(),
                      const ToolbarDivider(),
                      const ToolbarGap(),
                      ToolbarButton(
                        iconAsset: 'assets/icons/crop_square.svg',
                        isActive: state.activeTool == ActiveToolKind.createRect,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateRectToolEvent(),
                        ),
                      ),
                      const ToolbarGap(),
                      ToolbarButton(
                        iconAsset: 'assets/icons/circle.svg',
                        isActive:
                            state.activeTool == ActiveToolKind.createCircle,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateCircleToolEvent(),
                        ),
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

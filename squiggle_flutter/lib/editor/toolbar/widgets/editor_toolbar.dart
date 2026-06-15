import 'package:flutter/material.dart' hide Divider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/button.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/divider.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/gap.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/metrics.dart';
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
                borderRadius: BorderRadius.circular(outerRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(padding),
                child: SizedBox(
                  height: buttonSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Button(
                        iconAsset: 'assets/icons/arrow_selector_tool.svg',
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
                        isActive: state.activeTool == ActiveToolKind.createRect,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateRectToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/circle.svg',
                        isActive:
                            state.activeTool == ActiveToolKind.createCircle,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateCircleToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        iconAsset: 'assets/icons/line.svg',
                        isActive: state.activeTool == ActiveToolKind.createLine,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateLineToolEvent(),
                        ),
                      ),
                      const Gap(),
                      Button(
                        label: 'A',
                        isActive: state.activeTool == ActiveToolKind.createText,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateTextToolEvent(),
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

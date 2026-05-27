import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

const _toolbarPadding = 4.0;
const _toolbarGap = 2.0;
const _toolButtonSize = 36.0;
const _iconSize = 20.0;
const _dividerHeight = 20.0;
const _outerRadius = 12.0;
const _buttonRadius = 6.0;

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
                borderRadius: BorderRadius.circular(_outerRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_toolbarPadding),
                child: SizedBox(
                  height: _toolButtonSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ToolButton(
                        iconAsset: 'assets/icons/arrow_selector_tool.svg',
                        isActive: state.activeTool == ActiveToolKind.select,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateSelectToolEvent(),
                        ),
                      ),
                      const _ToolbarGap(),
                      const _ToolbarDivider(),
                      const _ToolbarGap(),
                      _ToolButton(
                        iconAsset: 'assets/icons/crop_square.svg',
                        isActive: state.activeTool == ActiveToolKind.createRect,
                        onPressed: () => context.read<ToolbarBloc>().add(
                          const ActivateCreateRectToolEvent(),
                        ),
                      ),
                      const _ToolbarGap(),
                      _ToolButton(
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

class _ToolbarGap extends StatelessWidget {
  const _ToolbarGap();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: _toolbarGap);
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: _dividerHeight,
      margin: const EdgeInsets.symmetric(horizontal: _toolbarGap),
      color: SquiggleColors.surface1,
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.iconAsset,
    required this.isActive,
    required this.onPressed,
  });

  final String iconAsset;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isActive
        ? SquiggleColors.surface1
        : (_hovering ? SquiggleColors.surface0 : null);
    final iconColor = widget.isActive
        ? SquiggleColors.text
        : SquiggleColors.subtext0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _toolButtonSize,
          height: _toolButtonSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            child: Center(
              child: SvgPicture.asset(
                widget.iconAsset,
                width: _iconSize,
                height: _iconSize,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exposes the editor-wide focus node used for tool keyboard shortcuts.
class EditorShortcutsScope extends InheritedWidget {
  const EditorShortcutsScope({
    required this.focusNode,
    required super.child,
    super.key,
  });

  final FocusNode focusNode;

  static EditorShortcutsScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<EditorShortcutsScope>();
  }

  void requestShortcutsFocus() {
    focusNode.requestFocus();
  }

  @override
  bool updateShouldNotify(EditorShortcutsScope oldWidget) {
    return focusNode != oldWidget.focusNode;
  }
}

/// Keyboard shortcuts for tool activation.
///
/// Holds keyboard focus at this level so R/C/V work whether the user last
/// interacted with the toolbar or the canvas.
class EditorShortcuts extends StatefulWidget {
  const EditorShortcuts({required this.child, super.key});

  final Widget child;

  @override
  State<EditorShortcuts> createState() => _EditorShortcutsState();
}

class _EditorShortcutsState extends State<EditorShortcuts> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorShortcutsScope(
      focusNode: _focusNode,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyV): ActivateSelectToolIntent(),
          SingleActivator(LogicalKeyboardKey.keyR):
              ActivateCreateRectToolIntent(),
          SingleActivator(LogicalKeyboardKey.keyC):
              ActivateCreateCircleToolIntent(),
          SingleActivator(LogicalKeyboardKey.backspace):
              DeleteSelectedFeaturesIntent(),
          SingleActivator(LogicalKeyboardKey.delete):
              DeleteSelectedFeaturesIntent(),
        },
        child: Actions(
          actions: {
            ActivateSelectToolIntent: CallbackAction<ActivateSelectToolIntent>(
              onInvoke: (_) {
                context.read<ToolbarBloc>().add(
                  const ActivateSelectToolEvent(),
                );
                return null;
              },
            ),
            ActivateCreateRectToolIntent:
                CallbackAction<ActivateCreateRectToolIntent>(
                  onInvoke: (_) {
                    context.read<ToolbarBloc>().add(
                      const ActivateCreateRectToolEvent(),
                    );
                    return null;
                  },
                ),
            ActivateCreateCircleToolIntent:
                CallbackAction<ActivateCreateCircleToolIntent>(
                  onInvoke: (_) {
                    context.read<ToolbarBloc>().add(
                      const ActivateCreateCircleToolEvent(),
                    );
                    return null;
                  },
                ),
            DeleteSelectedFeaturesIntent:
                CallbackAction<DeleteSelectedFeaturesIntent>(
                  onInvoke: (_) {
                    context.read<EditorBloc>().add(
                      const DeleteSelectedFeaturesEvent(),
                    );
                    return null;
                  },
                ),
          },
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            descendantsAreFocusable: false,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class ActivateSelectToolIntent extends Intent {
  const ActivateSelectToolIntent();
}

class ActivateCreateRectToolIntent extends Intent {
  const ActivateCreateRectToolIntent();
}

class ActivateCreateCircleToolIntent extends Intent {
  const ActivateCreateCircleToolIntent();
}

class DeleteSelectedFeaturesIntent extends Intent {
  const DeleteSelectedFeaturesIntent();
}

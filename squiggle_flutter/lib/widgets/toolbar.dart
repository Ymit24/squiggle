import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToolbarBloc, ToolbarState>(
      builder: (context, state) {
        return Material(
          color: const Color(0xFF181825),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _ToolButton(
                    label: 'Select (V)',
                    isActive: state.activeTool == ActiveToolKind.select,
                    onPressed: () => context.read<ToolbarBloc>().add(
                      const ActivateSelectToolEvent(),
                    ),
                  ),
                  _ToolButton(
                    label: 'Rectangle (R)',
                    isActive: state.activeTool == ActiveToolKind.createRect,
                    onPressed: () => context.read<ToolbarBloc>().add(
                      const ActivateCreateRectToolEvent(),
                    ),
                  ),
                  _ToolButton(
                    label: 'Circle (C)',
                    isActive: state.activeTool == ActiveToolKind.createCircle,
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
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF45475A) : null,
        foregroundColor: isActive
            ? const Color(0xFF89B4FA)
            : const Color(0xFFCDD6F4),
      ),
      onPressed: onPressed,
      child: Text(label),
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
                context.read<ToolbarBloc>().add(const ActivateSelectToolEvent());
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

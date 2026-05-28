import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/intents.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/scope.dart';

/// Keyboard shortcuts for tool activation.
///
/// Holds keyboard focus at this level so R/C/V work whether the user last
/// interacted with the toolbar or the canvas.
class ToolShortcuts extends StatefulWidget {
  const ToolShortcuts({required this.child, super.key});

  final Widget child;

  @override
  State<ToolShortcuts> createState() => _ToolShortcutsState();
}

class _ToolShortcutsState extends State<ToolShortcuts> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShortcutsScope(
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

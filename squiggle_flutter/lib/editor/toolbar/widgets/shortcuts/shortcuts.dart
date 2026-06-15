import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/intents.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/scope.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';

const _toolShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyV): ActivateSelectToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyR): ActivateCreateRectToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyC): ActivateCreateCircleToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyL): ActivateCreateLineToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyT): ActivateCreateTextToolIntent(),
  SingleActivator(LogicalKeyboardKey.backspace): DeleteSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.delete): DeleteSelectedFeaturesIntent(),
};

/// Keyboard shortcuts for tool activation.
///
/// Holds keyboard focus at this level so R/C/V work whether the user last
/// interacted with the toolbar or the canvas.
class ToolShortcuts extends StatefulWidget {
  const ToolShortcuts({
    required this.child,
    this.textEditOpen = false,
    super.key,
  });

  final Widget child;
  final bool textEditOpen;

  @override
  State<ToolShortcuts> createState() => _ToolShortcutsState();
}

class _ToolShortcutsState extends State<ToolShortcuts> {
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(ToolShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textEditOpen && !widget.textEditOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textEditOpen = widget.textEditOpen;
    return ShortcutsScope(
      focusNode: _focusNode,
      child: Shortcuts(
        shortcuts: textEditOpen ? const {} : _toolShortcuts,
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
            ActivateCreateLineToolIntent:
                CallbackAction<ActivateCreateLineToolIntent>(
                  onInvoke: (_) {
                    context.read<ToolbarBloc>().add(
                      const ActivateCreateLineToolEvent(),
                    );
                    return null;
                  },
                ),
            ActivateCreateTextToolIntent:
                CallbackAction<ActivateCreateTextToolIntent>(
                  onInvoke: (_) {
                    context.read<ToolbarBloc>().add(
                      const ActivateCreateTextToolEvent(),
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
            autofocus: !textEditOpen,
            descendantsAreFocusable: textEditOpen,
            onKeyEvent: (node, event) {
              if (textEditOpen) return KeyEventResult.ignored;
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (context.read<ToolRepository>().onKeyEvent(
                    context.read<DocumentRepository>(),
                    event,
                  )) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

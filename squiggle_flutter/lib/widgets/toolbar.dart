import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Keyboard shortcuts for tool activation.
class EditorShortcuts extends StatelessWidget {
  const EditorShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV): ActivateSelectToolIntent(),
      },
      child: Actions(
        actions: {
          ActivateSelectToolIntent: CallbackAction<ActivateSelectToolIntent>(
            onInvoke: (_) {
              context.read<ToolbarBloc>().add(const ActivateSelectToolEvent());
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class ActivateSelectToolIntent extends Intent {
  const ActivateSelectToolIntent();
}

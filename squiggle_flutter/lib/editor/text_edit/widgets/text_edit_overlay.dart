import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/inline_text_editor.dart';

class _CommitTextIntent extends Intent {
  const _CommitTextIntent();
}

/// Hosts the [InlineTextEditor] over the canvas. Escape, Cmd/Ctrl+Enter, or a
/// click anywhere else commits; there is no separate cancel. It does not cover
/// or block the canvas, so zoom, pan, and tool clicks keep working.
class TextEditOverlay extends StatefulWidget {
  const TextEditOverlay({
    super.key,
    required this.state,
    required this.editorContext,
  });

  final TextEditOpen state;
  final EditorContext editorContext;

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  final _focusNode = FocusNode();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = widget.state.initialContents;
    // Editing existing text starts with everything selected, ready to replace.
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.state is EditTextEditOpen ? text.length : 0,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _CommitTextIntent(),
          SingleActivator(LogicalKeyboardKey.enter, meta: true):
              _CommitTextIntent(),
          SingleActivator(LogicalKeyboardKey.enter, control: true):
              _CommitTextIntent(),
        },
        child: Actions(
          actions: {
            _CommitTextIntent: CallbackAction<_CommitTextIntent>(
              onInvoke: (_) {
                _commit();
                return null;
              },
            ),
          },
          child: FocusScope(
            autofocus: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InlineTextEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  layout: widget.state.layout,
                  editorContext: widget.editorContext,
                  // The click that lands outside also picks the new selection.
                  onTapOutside: () => _commit(selectCreated: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _commit({bool selectCreated = true}) {
    context.read<TextEditBloc>().add(
      TextEditSubmitted(_controller.text, selectCreated: selectCreated),
    );
  }
}

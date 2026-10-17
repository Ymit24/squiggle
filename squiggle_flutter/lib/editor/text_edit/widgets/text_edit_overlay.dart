import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/commit_text_edit.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/inline_text_editor.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/feature_kinds/feature_kind.dart';
import 'package:squiggle_flutter/models/label_layout.dart';

class _CommitTextIntent extends Intent {
  const _CommitTextIntent();
}

/// Hosts the [InlineTextEditor] over the canvas. Escape, Cmd/Ctrl+Enter, or a
/// click anywhere else commits; there is no separate cancel. It does not cover
/// or block the canvas, so zoom and pan keep working. Canvas clicks and drags
/// commit first (see `EditorInteractions`), so tools never act on a feature
/// whose text edit is still pending.
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

  bool get _editsText {
    final state = widget.state;
    return state is EditTextEditOpen &&
        widget.editorContext.document.featureById(state.featureId)?.kind
            is FeatureKindText;
  }

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
    _controller.addListener(_syncDraft);
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
                  layout: _layout,
                  outlined: widget.state is! EditTextEditOpen || _editsText,
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

  void _syncDraft() => widget.editorContext.textEdit.draft = _controller.text;

  /// Edited text follows its feature, so anything that changes the feature
  /// mid-edit cannot leave the field behind.
  LabelLayout _layout() {
    final state = widget.state;
    if (state is EditTextEditOpen) {
      final feature = widget.editorContext.document.featureById(
        state.featureId,
      );
      if (feature?.kind is LabelCapable) {
        return EditTextEditSession.forFeature(feature!).layout;
      }
    }
    return state.layout;
  }

  void _commit({bool selectCreated = true}) =>
      widget.editorContext.commitTextEdit(selectCreated: selectCreated);
}

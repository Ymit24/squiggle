import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/inline_text_editor.dart';
import 'package:squiggle_flutter/editor/text_edit_commands.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/widgets/pointer_claims.dart';
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
    required this.session,
    required this.pointerClaims,
    required this.editorContext,
  });

  final TextEditSession session;
  final PointerClaims pointerClaims;
  final EditorContext editorContext;

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  final _focusNode = FocusNode();
  late final TextEditingController _controller;

  bool get _editsText {
    final session = widget.session;
    return session is EditTextEditSession &&
        session.feature.kind is FeatureKindText;
  }

  @override
  void initState() {
    super.initState();
    final text = widget.session.initialContents;
    // Editing existing text starts with everything selected, ready to replace.
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.session is EditTextEditSession ? text.length : 0,
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
                  outlined:
                      widget.session is! EditTextEditSession || _editsText,
                  editorContext: widget.editorContext,
                  pointerClaims: widget.pointerClaims,
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
    final session = widget.session;
    if (session is EditTextEditSession &&
        session.feature.kind is LabelCapable) {
      return EditTextEditSession.forFeature(session.feature).layout;
    }
    return session.layout;
  }

  void _commit({bool selectCreated = true}) =>
      commitTextEdit(widget.editorContext, selectCreated: selectCreated);
}

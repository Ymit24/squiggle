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
/// click anywhere else commits; there is no separate cancel. It does not block
/// the canvas, so zoom and pan keep working and presses still reach the tools.
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
                // A press anywhere but the field commits the edit before the
                // tools see it, so they never act on a feature whose text is
                // still pending. The field sits above this in the Stack, so
                // presses on it stop there. Being a descendant of
                // `EditorInteractions`, this runs before its listener.
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _commit(selectCreated: false),
                ),
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
    final feature = switch (session) {
      CreateTextEditSession(:final draft) => draft,
      EditTextEditSession(:final feature) => feature,
    };
    final kind = feature.kind;
    if (kind is FeatureKindText) {
      return kind
          .labelLayoutFor(feature, _controller.text)
          .shifted(feature.parent?.globalOrigin ?? Offset.zero);
    }
    return kind is LabelCapable
        ? EditTextEditSession.forFeature(feature).layout
        : session.layout;
  }

  void _commit({bool selectCreated = true}) =>
      commitTextEdit(widget.editorContext, selectCreated: selectCreated);
}

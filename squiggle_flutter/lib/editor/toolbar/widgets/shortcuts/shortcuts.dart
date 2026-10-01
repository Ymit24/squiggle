import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/layer_order_commands.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/intents.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/scope.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';
import 'package:squiggle_flutter/services/paste_clipboard.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

const _brushKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

final _toolShortcuts = <ShortcutActivator, Intent>{
  for (final (index, key) in _brushKeys.indexed)
    SingleActivator(key, meta: true): ActivateBrushIntent(index),
  for (final (index, key) in _brushKeys.indexed)
    SingleActivator(key, control: true): ActivateBrushIntent(index),
  SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
      ReorderSelectedNodesIntent(LayerOrder.backward),
  SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
      ReorderSelectedNodesIntent(LayerOrder.backward),
  SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
      ReorderSelectedNodesIntent(LayerOrder.forward),
  SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
      ReorderSelectedNodesIntent(LayerOrder.forward),
  SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true, alt: true):
      ReorderSelectedNodesIntent(LayerOrder.back),
  SingleActivator(LogicalKeyboardKey.bracketLeft, control: true, alt: true):
      ReorderSelectedNodesIntent(LayerOrder.back),
  SingleActivator(LogicalKeyboardKey.bracketRight, meta: true, alt: true):
      ReorderSelectedNodesIntent(LayerOrder.front),
  SingleActivator(LogicalKeyboardKey.bracketRight, control: true, alt: true):
      ReorderSelectedNodesIntent(LayerOrder.front),
  SingleActivator(LogicalKeyboardKey.keyD, meta: true):
      DuplicateSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyD, control: true):
      DuplicateSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyV): ActivateSelectToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyQ): ToggleToolLockIntent(),
  SingleActivator(LogicalKeyboardKey.keyR): ActivateCreateRectToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyC): ActivateCreateCircleToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyL): ActivateCreateLineToolIntent(),
  SingleActivator(LogicalKeyboardKey.keyT): ActivateCreateTextToolIntent(),
  SingleActivator(LogicalKeyboardKey.digit1): ActivateSelectToolIntent(),
  SingleActivator(LogicalKeyboardKey.digit2): ActivateCreateRectToolIntent(),
  SingleActivator(LogicalKeyboardKey.digit3): ActivateCreateCircleToolIntent(),
  SingleActivator(LogicalKeyboardKey.digit4): ActivateCreateLineToolIntent(),
  SingleActivator(LogicalKeyboardKey.digit5): ActivateCreateTextToolIntent(),
  SingleActivator(LogicalKeyboardKey.backspace): DeleteSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.delete): DeleteSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyC, meta: true):
      CopySelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyC, control: true):
      CopySelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyX, meta: true):
      CutSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyX, control: true):
      CutSelectedFeaturesIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
      RedoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
      RedoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyY, meta: true): RedoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoDocumentIntent(),
  SingleActivator(LogicalKeyboardKey.keyV, meta: true): PasteImageIntent(),
  SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteImageIntent(),
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
            ActivateBrushIntent: CallbackAction<ActivateBrushIntent>(
              onInvoke: (intent) {
                final editor = context.read<EditorContext>();
                if (!textEditOpen &&
                    editor.selection.selectedNodeIds.isEmpty &&
                    editor.drawingInspectorKind != null &&
                    intent.index < editor.document.session.brushes.length) {
                  editor.activateBrush(
                    editor.document.session.brushes[intent.index].id,
                  );
                }
                return null;
              },
            ),
            ToggleToolLockIntent: CallbackAction<ToggleToolLockIntent>(
              onInvoke: (_) {
                if (!textEditOpen) {
                  context.read<EditorContext>().tool.toggleLock();
                }
                return null;
              },
            ),
            ReorderSelectedNodesIntent:
                CallbackAction<ReorderSelectedNodesIntent>(
                  onInvoke: (intent) {
                    if (!textEditOpen) {
                      reorderSelectedNodes(
                        context.read<EditorContext>(),
                        intent.action,
                      );
                    }
                    return null;
                  },
                ),
            ActivateSelectToolIntent: CallbackAction<ActivateSelectToolIntent>(
              onInvoke: (_) {
                context.read<EditorContext>().setTool(SelectTool());
                return null;
              },
            ),
            ActivateCreateRectToolIntent:
                CallbackAction<ActivateCreateRectToolIntent>(
                  onInvoke: (_) {
                    context.read<EditorContext>().setTool(
                      CreateFeatureTool.rect(),
                    );
                    return null;
                  },
                ),
            ActivateCreateCircleToolIntent:
                CallbackAction<ActivateCreateCircleToolIntent>(
                  onInvoke: (_) {
                    context.read<EditorContext>().setTool(
                      CreateFeatureTool.circle(),
                    );
                    return null;
                  },
                ),
            ActivateCreateLineToolIntent:
                CallbackAction<ActivateCreateLineToolIntent>(
                  onInvoke: (_) {
                    context.read<EditorContext>().setTool(CreateLineTool());
                    return null;
                  },
                ),
            ActivateCreateTextToolIntent:
                CallbackAction<ActivateCreateTextToolIntent>(
                  onInvoke: (_) {
                    context.read<EditorContext>().setTool(CreateTextTool());
                    return null;
                  },
                ),
            CopySelectedFeaturesIntent:
                CallbackAction<CopySelectedFeaturesIntent>(
                  onInvoke: (_) {
                    if (textEditOpen) {
                      return null;
                    }
                    copySelectedNodesToClipboard(
                      context: context.read<EditorContext>(),
                      imageRepository: context.read<ImageRepository>(),
                    );
                    return null;
                  },
                ),
            CutSelectedFeaturesIntent:
                CallbackAction<CutSelectedFeaturesIntent>(
                  onInvoke: (_) {
                    if (textEditOpen) return null;
                    cutSelectedNodesToClipboard(
                      context: context.read<EditorContext>(),
                      imageRepository: context.read<ImageRepository>(),
                    );
                    return null;
                  },
                ),
            DuplicateSelectedFeaturesIntent:
                CallbackAction<DuplicateSelectedFeaturesIntent>(
                  onInvoke: (_) {
                    if (textEditOpen) return null;
                    duplicateSelectedNodes(context.read<EditorContext>());
                    return null;
                  },
                ),
            PasteImageIntent: CallbackAction<PasteImageIntent>(
              onInvoke: (_) {
                if (textEditOpen) {
                  return null;
                }
                pasteFromClipboard(
                  context: context.read<EditorContext>(),
                  imageRepository: context.read<ImageRepository>(),
                );
                return null;
              },
            ),
            UndoDocumentIntent: CallbackAction<UndoDocumentIntent>(
              onInvoke: (_) {
                context.read<EditorContext>().undo();
                return null;
              },
            ),
            RedoDocumentIntent: CallbackAction<RedoDocumentIntent>(
              onInvoke: (_) {
                context.read<EditorContext>().redo();
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
              final context_ = context.read<EditorContext>();
              if (context_.tool.onKeyEvent(context_, event)) {
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

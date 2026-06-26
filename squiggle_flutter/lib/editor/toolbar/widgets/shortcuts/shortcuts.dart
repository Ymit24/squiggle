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
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/services/feature_clipboard.dart';
import 'package:squiggle_flutter/services/paste_image.dart';
import 'package:squiggle_flutter/services/paste_text.dart';

const _toolShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyV): ActivateSelectToolIntent(),
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
            CopySelectedFeaturesIntent:
                CallbackAction<CopySelectedFeaturesIntent>(
                  onInvoke: (_) {
                    if (textEditOpen) {
                      return null;
                    }
                    copySelectedFeaturesToClipboard(
                      documentRepository: context.read<DocumentRepository>(),
                      selectionRepository: context.read<SelectionRepository>(),
                      imageRepository: context.read<ImageRepository>(),
                    );
                    return null;
                  },
                ),
            PasteImageIntent: CallbackAction<PasteImageIntent>(
              onInvoke: (_) {
                if (textEditOpen) {
                  return null;
                }
                _pasteFromClipboard(context);
                return null;
              },
            ),
            UndoDocumentIntent: CallbackAction<UndoDocumentIntent>(
              onInvoke: (_) {
                context.read<ToolbarBloc>().add(const UndoDocumentEvent());
                return null;
              },
            ),
            RedoDocumentIntent: CallbackAction<RedoDocumentIntent>(
              onInvoke: (_) {
                context.read<ToolbarBloc>().add(const RedoDocumentEvent());
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

Future<void> _pasteFromClipboard(BuildContext context) async {
  final documentRepository = context.read<DocumentRepository>();
  final viewportRepository = context.read<ViewportRepository>();
  final imageRepository = context.read<ImageRepository>();

  final pastedFeatures = await pasteFeaturesFromClipboard(
    documentRepository: documentRepository,
    viewportRepository: viewportRepository,
    imageRepository: imageRepository,
  );
  if (pastedFeatures) {
    return;
  }

  final pastedText = await pasteTextFromClipboard(
    documentRepository: documentRepository,
    viewportRepository: viewportRepository,
  );
  if (pastedText) {
    return;
  }

  await pasteImageFromClipboard(
    imageRepository: imageRepository,
    documentRepository: documentRepository,
    viewportRepository: viewportRepository,
  );
}

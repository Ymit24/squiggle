import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Selection gestures cancel on Escape unless a state overrides key handling.
abstract class SelectInteractionState extends InteractionState<SelectTool> {
  SelectInteractionState({required super.parent});

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      parent.cancelInteraction(context);
      return true;
    }
    return false;
  }
}

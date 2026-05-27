import 'package:flutter/widgets.dart';

/// Exposes the editor-wide focus node used for tool keyboard shortcuts.
class EditorShortcutsScope extends InheritedWidget {
  const EditorShortcutsScope({
    required this.focusNode,
    required super.child,
    super.key,
  });

  final FocusNode focusNode;

  static EditorShortcutsScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<EditorShortcutsScope>();
  }

  void requestShortcutsFocus() {
    focusNode.requestFocus();
  }

  @override
  bool updateShouldNotify(EditorShortcutsScope oldWidget) {
    return focusNode != oldWidget.focusNode;
  }
}

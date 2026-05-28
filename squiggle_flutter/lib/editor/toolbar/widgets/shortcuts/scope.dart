import 'package:flutter/widgets.dart';

/// Exposes the editor-wide focus node used for tool keyboard shortcuts.
class ShortcutsScope extends InheritedWidget {
  const ShortcutsScope({
    required this.focusNode,
    required super.child,
    super.key,
  });

  final FocusNode focusNode;

  static ShortcutsScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ShortcutsScope>();
  }

  void requestShortcutsFocus() {
    focusNode.requestFocus();
  }

  @override
  bool updateShouldNotify(ShortcutsScope oldWidget) {
    return focusNode != oldWidget.focusNode;
  }
}

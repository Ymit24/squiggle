import 'package:flutter_test/flutter_test.dart';

import 'painting/text_painter_cases.dart' as text_painter;
import 'widgets/fling_controller_cases.dart' as fling_controller;
import 'widgets/shortcuts_cases.dart' as shortcuts;
import 'widgets/text_edit_panel_cases.dart' as text_edit_panel;

void main() {
  group('painting/text_painter', text_painter.main);
  group('widgets/fling_controller', fling_controller.main);
  group('widgets/shortcuts', shortcuts.main);
  group('widgets/text_edit_panel', text_edit_panel.main);
}

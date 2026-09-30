import 'package:flutter_test/flutter_test.dart';

import 'tools/select_tool/box_selection_state_cases.dart' as box_selection_state;
import 'tools/select_tool/click_canvas_state_cases.dart' as click_canvas_state;
import 'tools/select_tool/click_node_state_cases.dart' as click_node_state;
import 'tools/select_tool/drag_polyline_handle_state_cases.dart' as drag_polyline_handle_state;
import 'tools/select_tool/duplicate_state_cases.dart' as duplicate_state;
import 'tools/select_tool/grouping_cases.dart' as grouping;
import 'tools/select_tool/idle_interaction_state_cases.dart' as idle_interaction_state;
import 'tools/select_tool/resize_state_cases.dart' as resize_state;
import 'tools/select_tool/translate_state_cases.dart' as translate_state;

void main() {
  group('tools/select_tool/box_selection_state', box_selection_state.main);
  group('tools/select_tool/click_canvas_state', click_canvas_state.main);
  group('tools/select_tool/click_node_state', click_node_state.main);
  group('tools/select_tool/drag_polyline_handle_state', drag_polyline_handle_state.main);
  group('tools/select_tool/duplicate_state', duplicate_state.main);
  group('tools/select_tool/grouping', grouping.main);
  group('tools/select_tool/idle_interaction_state', idle_interaction_state.main);
  group('tools/select_tool/resize_state', resize_state.main);
  group('tools/select_tool/translate_state', translate_state.main);
}

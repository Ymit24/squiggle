import 'package:flutter_test/flutter_test.dart';

import 'tools/create_feature_tool_cases.dart' as create_feature_tool;
import 'tools/create_line_tool_cases.dart' as create_line_tool;
import 'tools/create_text_tool_cases.dart' as create_text_tool;
import 'tools/select_tool_cases.dart' as select_tool;

void main() {
  group('tools/create_feature_tool', create_feature_tool.main);
  group('tools/create_line_tool', create_line_tool.main);
  group('tools/create_text_tool', create_text_tool.main);
  group('tools/select_tool', select_tool.main);
}

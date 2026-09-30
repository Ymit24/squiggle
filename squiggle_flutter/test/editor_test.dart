import 'package:flutter_test/flutter_test.dart';

import 'editor/bloc_cases.dart' as bloc;
import 'editor/editor_context_inspector_values_cases.dart' as editor_context_inspector_values;
import 'editor/history/container_edit_cases.dart' as container_edit;
import 'editor/history/edit_cases.dart' as edit;
import 'editor/history/history_cases.dart' as history;
import 'editor/text_edit_bloc_cases.dart' as text_edit_bloc;
import 'editor/widgets/back_to_content_cases.dart' as back_to_content;

void main() {
  group('editor/bloc', bloc.main);
  group('editor/editor_context_inspector_values', editor_context_inspector_values.main);
  group('editor/history/container_edit', container_edit.main);
  group('editor/history/edit', edit.main);
  group('editor/history/history', history.main);
  group('editor/text_edit_bloc', text_edit_bloc.main);
  group('editor/widgets/back_to_content', back_to_content.main);
}

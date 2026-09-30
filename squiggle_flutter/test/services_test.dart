import 'package:flutter_test/flutter_test.dart';

import 'services/node_clipboard_cases.dart' as node_clipboard;
import 'services/paste_image_cases.dart' as paste_image;
import 'services/paste_text_cases.dart' as paste_text;

void main() {
  group('services/node_clipboard', node_clipboard.main);
  group('services/paste_image', paste_image.main);
  group('services/paste_text', paste_text.main);
}

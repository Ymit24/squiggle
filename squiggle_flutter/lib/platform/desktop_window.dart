import 'dart:ui';

import 'package:window_manager/window_manager.dart';

Future<void> initializeDesktopWindow(String title) async {
  await windowManager.ensureInitialized();
  await windowManager.setTitle(title);
  await windowManager.setMinimumSize(const Size(640, 480));
}

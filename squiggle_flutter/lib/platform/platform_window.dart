import 'package:squiggle_flutter/platform/desktop_window.dart'
    if (dart.library.js_interop) 'package:squiggle_flutter/platform/desktop_window_web.dart'
    as platform;

Future<void> disableBrowserContextMenu() =>
    platform.disableBrowserContextMenu();

Future<void> initializeDesktopWindow(String title) =>
    platform.initializeDesktopWindow(title);

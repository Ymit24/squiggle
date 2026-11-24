// The browser's native context menu is disabled in web/index.html. Keeping
// this platform hook as a no-op avoids making startup depend on a JSON
// platform-channel round trip before Flutter has mounted the app.
Future<void> disableBrowserContextMenu() async {}

Future<void> initializeDesktopWindow(String title) async {}

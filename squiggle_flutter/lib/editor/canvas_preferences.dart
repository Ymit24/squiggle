import 'package:squiggle_flutter/preferences/preferences.dart';

/// Whether the editor paints its world-space grid behind the canvas.
const showGridPreference = BoolPreference('canvas.showGrid', true);

/// Shortcut that toggles [showGridPreference] in the editor.
const showGridShortcut = "⌘'";

void toggleShowGrid(Preferences preferences) =>
    preferences.set(showGridPreference, !preferences.get(showGridPreference));

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';

/// Light, dark, or following the system. Dark until chosen, matching the
/// app's look before this preference existed.
const themeModePreference = EnumPreference(
  'appearance.themeMode',
  ThemeMode.dark,
  ThemeMode.values,
);

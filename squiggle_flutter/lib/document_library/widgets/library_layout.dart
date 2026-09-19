import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_spacing.dart';

const compactLibraryBreakpoint = 760.0;
const maxLibraryWidth = 1160.0;
const libraryHeaderControlHeight = kControlHeight;

bool isCompactLibrary(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactLibraryBreakpoint;

double libraryHorizontalPadding(BuildContext context) =>
    isCompactLibrary(context) ? 16.0 : 40.0;

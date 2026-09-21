import 'package:flutter/widgets.dart';

const compactLibraryBreakpoint = 760.0;
const maxLibraryWidth = 1160.0;
const libraryHeaderControlHeight = 38.0;

bool isCompactLibrary(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactLibraryBreakpoint;

const double kLibraryHorizontalPadding = 16.0;

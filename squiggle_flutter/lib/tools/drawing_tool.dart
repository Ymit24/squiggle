import 'package:squiggle_flutter/models/feature.dart';

/// A tool that can supply fresh style defaults for the drawing inspector.
abstract interface class DrawingTool {
  FeatureKind createDrawingKind();
}

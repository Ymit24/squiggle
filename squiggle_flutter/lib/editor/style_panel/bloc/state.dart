import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

sealed class StylePanelState {
  const StylePanelState();
}

/// Nothing selected — panel is hidden.
final class StylePanelHiddenState extends StylePanelState {
  const StylePanelHiddenState();
}

/// One or more features selected — panel is visible with active-style indicators.
final class StylePanelShowingState extends StylePanelState {
  const StylePanelShowingState({
    required this.selectedFeatureIds,
    required this.activeStrokePresetIndex,
    required this.isStrokeNone,
    required this.strokeMixed,
    required this.strokeWidthMixed,
    required this.activeFillPresetIndex,
    required this.isFillNone,
    required this.fillMixed,
    required this.activeStrokeWidth,
    required this.canClearStroke,
    required this.canClearFill,
    required this.showFontSize,
    required this.fontSizeMixed,
    required this.activeFontSize,
    required this.horizontalAlignmentMixed,
    required this.activeHorizontalAlignment,
    required this.verticalAlignmentMixed,
    required this.activeVerticalAlignment,
  });

  final List<FeatureId> selectedFeatureIds;
  final int? activeStrokePresetIndex;
  final bool isStrokeNone;
  final bool strokeMixed;
  final bool strokeWidthMixed;
  final int? activeFillPresetIndex;
  final bool isFillNone;
  final bool fillMixed;
  final StrokeWidthPreset? activeStrokeWidth;
  final bool canClearStroke;
  final bool canClearFill;
  final bool showFontSize;
  final bool fontSizeMixed;
  final FontSizePreset? activeFontSize;
  final bool horizontalAlignmentMixed;
  final TextHorizontalAlignment? activeHorizontalAlignment;
  final bool verticalAlignmentMixed;
  final TextVerticalAlignment? activeVerticalAlignment;
}

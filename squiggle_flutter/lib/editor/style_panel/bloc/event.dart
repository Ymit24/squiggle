import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_layout.dart';

abstract class StylePanelEvent {
  const StylePanelEvent();
}

class RequestWatchStylePanelStateEvent extends StylePanelEvent {
  const RequestWatchStylePanelStateEvent();
}

class SetStrokePresetEvent extends StylePanelEvent {
  const SetStrokePresetEvent(this.index);

  final int index;
}

class ClearStrokeEvent extends StylePanelEvent {
  const ClearStrokeEvent();
}

class SetFillPresetEvent extends StylePanelEvent {
  const SetFillPresetEvent(this.index);

  final int index;
}

class ClearFillEvent extends StylePanelEvent {
  const ClearFillEvent();
}

class SetStrokeWidthEvent extends StylePanelEvent {
  const SetStrokeWidthEvent(this.preset);

  final StrokeWidthPreset preset;
}

class SetFontSizeEvent extends StylePanelEvent {
  const SetFontSizeEvent(this.preset);

  final FontSizePreset preset;
}

class SetTextHorizontalAlignmentEvent extends StylePanelEvent {
  const SetTextHorizontalAlignmentEvent(this.alignment);

  final TextHorizontalAlignment alignment;
}

class SetTextVerticalAlignmentEvent extends StylePanelEvent {
  const SetTextVerticalAlignmentEvent(this.alignment);

  final TextVerticalAlignment alignment;
}

class AlignFeaturesEvent extends StylePanelEvent {
  const AlignFeaturesEvent(this.alignment);

  final FeatureAlignment alignment;
}

class DistributeFeaturesEvent extends StylePanelEvent {
  const DistributeFeaturesEvent(this.distribution);

  final FeatureDistribution distribution;
}

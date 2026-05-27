import 'package:squiggle_flutter/models/feature_id.dart';

abstract class EditorEvent {
  const EditorEvent();
}

class SelectFeatureEvent extends EditorEvent {
  const SelectFeatureEvent(this.featureId);

  final FeatureId featureId;
}

class DeselectFeatureEvent extends EditorEvent {
  const DeselectFeatureEvent(this.featureId);

  final FeatureId featureId;
}

import 'package:flutter_test/flutter_test.dart';

import 'models/camera_cases.dart' as camera;
import 'models/data_node_equality_cases.dart' as data_node_equality;
import 'models/document_cases.dart' as document;
import 'models/feature_cases.dart' as feature;
import 'models/feature_geometry_cases.dart' as feature_geometry;
import 'models/group_cases.dart' as group_cases;
import 'models/node_layout_cases.dart' as node_layout;
import 'models/text_alignment_cases.dart' as text_alignment;
import 'models/stroke_width_preset_cases.dart' as stroke_width_preset;
import 'models/font_size_preset_cases.dart' as font_size_preset;

void main() {
  group('models/camera', camera.main);
  group('models/data_node_equality', data_node_equality.main);
  group('models/document', document.main);
  group('models/feature', feature.main);
  group('models/feature_geometry', feature_geometry.main);
  group('models/group', group_cases.main);
  group('models/node_layout', node_layout.main);
  group('models/text_alignment', text_alignment.main);
  group('models/stroke_width_preset', stroke_width_preset.main);
  group('models/font_size_preset', font_size_preset.main);
}

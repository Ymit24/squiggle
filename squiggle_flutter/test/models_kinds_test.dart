import 'package:flutter_test/flutter_test.dart';

import 'models/feature_kind_circle_cases.dart' as feature_kind_circle;
import 'models/feature_kind_image_cases.dart' as feature_kind_image;
import 'models/feature_kind_label_paint_cases.dart' as feature_kind_label_paint;
import 'models/feature_kind_polyline_cases.dart' as feature_kind_polyline;
import 'models/feature_kind_rectangle_cases.dart' as feature_kind_rectangle;
import 'models/feature_kind_text_cases.dart' as feature_kind_text;
import 'models/feature_kinds/inspector_field_cases.dart' as inspector_field;

void main() {
  group('models/feature_kind_circle', feature_kind_circle.main);
  group('models/feature_kind_image', feature_kind_image.main);
  group('models/feature_kind_label_paint', feature_kind_label_paint.main);
  group('models/feature_kind_polyline', feature_kind_polyline.main);
  group('models/feature_kind_rectangle', feature_kind_rectangle.main);
  group('models/feature_kind_text', feature_kind_text.main);
  group('models/feature_kinds/inspector_field', inspector_field.main);
}

import 'package:squiggle_flutter/editor/style_panel/widgets/metrics.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

/// Representative features, rendered with the same painters as the canvas.
class BrushPreview extends StatelessWidget {
  const BrushPreview({
    super.key,
    required this.brush,
    required this.imageRepository,
  });

  final BrushProfile brush;
  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: brushPreviewHeight,
    width: double.infinity,
    child: CustomPaint(
      painter: _BrushPainter(Map.of(brush.values), imageRepository),
    ),
  );
}

class _BrushPainter extends CustomPainter {
  _BrushPainter(this.values, this.imageRepository);
  final Map<String, Object?> values;
  final ImageRepository imageRepository;

  @override
  void paint(Canvas canvas, Size size) {
    final brush = BrushProfile(id: 'preview', name: '', values: values);
    final rectangle = FeatureKindRectangle();
    final text = FeatureKindText('Aa');
    final line = FeatureKindPolyline([
      Offset.zero,
      Offset(math.max(12, size.width - 76), 0),
    ]);
    for (final kind in <FeatureKind>[rectangle, text, line]) {
      brush.applyTo(kind);
    }
    // Bound the sample scale; do not fit the whole composition to font size or
    // stroke width, which would make all brush thumbnails look identical.
    rectangle.strokeWidth = (rectangle.strokeWidth / 4).clamp(0.5, 4);
    line.strokeWidth = (line.strokeWidth / 4).clamp(0.5, 4);
    text.fontSize = (text.fontSize * 0.65).clamp(9, 22);
    final samples = [
      Feature(
        origin: const Offset(3, 3),
        size: const Size(18, 18),
        kind: rectangle,
      ),
      Feature(
        origin: const Offset(29, 1),
        size: const Size(32, 22),
        kind: text,
      ),
      Feature(origin: const Offset(69, 12), size: Size.zero, kind: line),
    ];
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final sample in samples) {
      sample.paint(canvas, imageRepository);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrushPainter oldDelegate) =>
      !mapEquals(values, oldDelegate.values);
}

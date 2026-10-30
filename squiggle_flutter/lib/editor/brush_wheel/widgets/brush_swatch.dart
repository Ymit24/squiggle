import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

/// A square sample of what [kind] looks like when drawn with [brush].
///
/// [kind] supplies the tool's fresh defaults and is never mutated. Repaints
/// key off its type, since a tool's defaults only differ by kind.
class BrushSwatch extends StatelessWidget {
  const BrushSwatch({
    super.key,
    required this.brush,
    required this.kind,
    required this.imageRepository,
    this.size = 48,
  });

  final BrushProfile brush;
  final FeatureKind kind;
  final ImageRepository imageRepository;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _SwatchPainter(Map.of(brush.values), kind, imageRepository),
    ),
  );
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.values, this.kind, this.imageRepository);

  final Map<String, Object?> values;
  final FeatureKind kind;
  final ImageRepository imageRepository;

  @override
  void paint(Canvas canvas, Size size) {
    final sample = kind.clone();
    BrushProfile(id: 'swatch', name: '', values: values).applyTo(sample);
    final feature = _place(sample, size);
    if (feature == null) {
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    feature.paint(canvas, imageRepository);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SwatchPainter oldDelegate) =>
      !mapEquals(values, oldDelegate.values) ||
      kind.runtimeType != oldDelegate.kind.runtimeType;

  /// Fits the sample into [size]. Widths and font sizes are compressed rather
  /// than scaled to fit, so thin and thick brushes stay distinguishable.
  Feature? _place(FeatureKind sample, Size size) {
    final inset = size.shortestSide * 0.23;
    final box = (Offset.zero & size).deflate(inset);
    if (sample case final StrokeWidthCapable capable) {
      capable.strokeWidth = (capable.strokeWidth / 3).clamp(1, 5);
    }
    switch (sample) {
      case FeatureKindRectangle() || FeatureKindCircle():
        return Feature(origin: box.topLeft, size: box.size, kind: sample);
      case FeatureKindPolyline():
        sample.localPoints = [
          box.bottomLeft - box.topLeft,
          box.topRight - box.topLeft,
        ];
        return Feature(origin: box.topLeft, size: box.size, kind: sample);
      case FeatureKindText():
        sample
          ..label = 'Aa'
          ..fontSize = (sample.fontSize * 0.6).clamp(10, 20)
          ..horizontalAlignment = TextHorizontalAlignment.center;
        return Feature(origin: Offset.zero, size: size, kind: sample);
      case FeatureKindImage():
        return null;
    }
  }
}

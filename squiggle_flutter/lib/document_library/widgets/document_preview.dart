import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Renders a scaled-down view of a document's actual features.
class DocumentPreview extends StatelessWidget {
  const DocumentPreview({
    super.key,
    required this.features,
    required this.imageRepository,
  });

  final List<Feature> features;
  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _DocumentPreviewPainter(
          features: features,
          imageRepository: imageRepository,
          gridColor: SquiggleColors.surface1.withValues(alpha: 0.55),
          baseColor: theme.colors.base,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DocumentPreviewPainter extends CustomPainter {
  _DocumentPreviewPainter({
    required this.features,
    required this.imageRepository,
    required this.gridColor,
    required this.baseColor,
  });

  final List<Feature> features;
  final ImageRepository imageRepository;
  final Color gridColor;
  final Color baseColor;

  static const _gridCellSize = 128.0;
  static const _emptyView = Rect.fromLTWH(-256, -192, 512, 384);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final contentBounds = _contentBounds(features);
    final scale = _fitScale(contentBounds, size);
    final offset = _fitOffset(contentBounds, size, scale);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    _drawGrid(canvas, contentBounds);
    for (final feature in features) {
      feature.paint(canvas, imageRepository);
    }
    canvas.restore();
  }

  Rect _contentBounds(List<Feature> features) {
    if (features.isEmpty) {
      return _emptyView;
    }

    var bounds = features.first.bounds();
    for (var i = 1; i < features.length; i++) {
      bounds = bounds.expandToInclude(features[i].bounds());
    }

    final padding = _paddingFor(bounds);
    return bounds.inflate(padding);
  }

  double _fitScale(Rect content, Size size) {
    if (content.width <= 0 || content.height <= 0) {
      return 1;
    }
    return math.min(
      size.width / content.width,
      size.height / content.height,
    );
  }

  double _paddingFor(Rect bounds) {
    return math.max(
      48.0,
      math.max(bounds.width, bounds.height) * 0.12,
    );
  }

  Offset _fitOffset(Rect content, Size size, double scale) {
    final fittedWidth = content.width * scale;
    final fittedHeight = content.height * scale;
    return Offset(
      (size.width - fittedWidth) / 2 - content.left * scale,
      (size.height - fittedHeight) / 2 - content.top * scale,
    );
  }

  void _drawGrid(Canvas canvas, Rect world) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final firstX =
        (world.left / _gridCellSize).floorToDouble() * _gridCellSize;
    final firstY =
        (world.top / _gridCellSize).floorToDouble() * _gridCellSize;

    for (var x = firstX; x <= world.right; x += _gridCellSize) {
      canvas.drawLine(
        Offset(x, world.top),
        Offset(x, world.bottom),
        paint,
      );
    }
    for (var y = firstY; y <= world.bottom; y += _gridCellSize) {
      canvas.drawLine(
        Offset(world.left, y),
        Offset(world.right, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DocumentPreviewPainter oldDelegate) {
    return oldDelegate.features != features ||
        oldDelegate.imageRepository != imageRepository;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DocumentPreview extends StatelessWidget {
  const DocumentPreview({
    super.key,
    required this.nodes,
    required this.imageRepository,
    this.backgroundColor = SquiggleColors.surface0,
    this.dotColor = SquiggleColors.surface1,
  });

  final List<Node> nodes;
  final ImageRepository imageRepository;
  final Color backgroundColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.squiggleTheme.radii.control),
      child: CustomPaint(
        painter: _DocumentPreviewPainter(
          nodes: nodes,
          imageRepository: imageRepository,
          backgroundColor: backgroundColor,
          dotColor: dotColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DocumentPreviewPainter extends CustomPainter {
  _DocumentPreviewPainter({
    required this.nodes,
    required this.imageRepository,
    required this.backgroundColor,
    required this.dotColor,
  });

  final List<Node> nodes;
  final ImageRepository imageRepository;
  final Color backgroundColor;
  final Color dotColor;

  static const _dotGap = 22.0;
  static const _dotRadius = 1.1;
  static const _minViewport = Size(560, 420);
  static const _maxScale = 1.25;
  static const _minScale = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    _drawDotGrid(canvas, size);

    if (nodes.isEmpty) return;

    final content = _contentBounds(nodes);
    final scale = _fitScale(content, size);
    final offset = _fitOffset(content, size, scale);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    for (final node in nodes) {
      node.paint(canvas, imageRepository);
    }
    canvas.restore();
  }

  Rect _contentBounds(List<Node> nodes) {
    var bounds = nodes.first.localBounds();
    for (var i = 1; i < nodes.length; i++) {
      bounds = bounds.expandToInclude(nodes[i].localBounds());
    }
    final w = math.max(bounds.width, 64.0);
    final h = math.max(bounds.height, 64.0);
    final center = bounds.center;
    final padded = Rect.fromCenter(center: center, width: w, height: h);
    final pad = math.max(64.0, math.max(w, h) * 0.18);
    return padded.inflate(pad);
  }

  double _fitScale(Rect content, Size size) {
    final effectiveW = math.max(content.width, _minViewport.width);
    final effectiveH = math.max(content.height, _minViewport.height);
    final raw = math.min(size.width / effectiveW, size.height / effectiveH);
    return raw.clamp(_minScale, _maxScale);
  }

  Offset _fitOffset(Rect content, Size size, double scale) {
    final fittedW = content.width * scale;
    final fittedH = content.height * scale;
    return Offset(
      (size.width - fittedW) / 2 - content.left * scale,
      (size.height - fittedH) / 2 - content.top * scale,
    );
  }

  void _drawDotGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor.withValues(alpha: 0.55);
    for (var y = _dotGap / 2; y < size.height; y += _dotGap) {
      for (var x = _dotGap / 2; x < size.width; x += _dotGap) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DocumentPreviewPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.imageRepository != imageRepository ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor;
  }
}

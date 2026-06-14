part of 'feature_kind.dart';

final class FeatureKindText extends FeatureKind {
  const FeatureKindText(
    this.contents, {
    this.fontSize = defaultFontSize,
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

  final String contents;
  final double fontSize;

  @override
  void paint(Feature feature, Canvas canvas) {
    if (contents.isEmpty) return;

    final worldBounds = feature.bounds();
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize,
      textDirection: TextDirection.ltr,
    );
    final constraints = ui.ParagraphConstraints(width: worldBounds.width);
    final position = worldBounds.topLeft;

    final strokeBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(
        ui.TextStyle(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = strokeColor,
          fontSize: fontSize,
        ),
      )
      ..addText(contents);
    final strokeParagraph = strokeBuilder.build()..layout(constraints);
    canvas.drawParagraph(strokeParagraph, position);

    final fillBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(ui.TextStyle(color: fillColor, fontSize: fontSize))
      ..addText(contents);
    final fillParagraph = fillBuilder.build()..layout(constraints);
    canvas.drawParagraph(fillParagraph, position);
  }
}

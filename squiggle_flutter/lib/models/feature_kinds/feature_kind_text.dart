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

  Size measureContents({required double width, required double fontSize}) {
    if (contents.isEmpty) {
      return Size(width, fontSize);
    }

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize,
      textDirection: TextDirection.ltr,
    );
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(ui.TextStyle(fontSize: fontSize))
      ..addText(contents);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    return Size(width, paragraph.height.clamp(fontSize, double.infinity));
  }

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

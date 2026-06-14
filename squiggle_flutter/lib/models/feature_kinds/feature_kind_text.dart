part of 'feature_kind.dart';

final class FeatureKindText extends FeatureKind {
  const FeatureKindText(this.contents, {this.fontSize = 24});

  final String contents;
  final double fontSize;

  @override
  void paint(Feature feature, Canvas canvas) {
    if (contents.isEmpty) return;

    final worldBounds = feature.bounds();
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        textDirection: TextDirection.ltr,
      ),
    )..pushStyle(ui.TextStyle(color: const Color(0xFFCDD6F4)));
    builder.addText(contents);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: worldBounds.width));

    canvas.drawParagraph(paragraph, worldBounds.topLeft);
  }
}

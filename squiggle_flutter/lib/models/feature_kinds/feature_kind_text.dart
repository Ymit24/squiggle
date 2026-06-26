part of 'feature_kind.dart';

const kMinTextFontSize = 1.0;
const kMaxTextFontSize = 1000.0;

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
    final clampedWidth = width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : width;
    if (contents.isEmpty) {
      return Size(clampedWidth, fontSize);
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
      ..layout(ui.ParagraphConstraints(width: clampedWidth));
    return Size(
      clampedWidth,
      paragraph.height.clamp(fontSize, double.infinity),
    );
  }

  /// Largest [fontSize] where [contents] fits within [width] x [height].
  double fontSizeFillingBounds({
    required double width,
    required double height,
  }) {
    final clampedWidth = width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : width;
    final clampedHeight = height < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : height;

    if (contents.isEmpty) {
      return clampedHeight.clamp(kMinTextFontSize, kMaxTextFontSize);
    }

    if (measureContents(
      width: clampedWidth,
      fontSize: kMinTextFontSize,
    ).height > clampedHeight) {
      return kMinTextFontSize;
    }

    var lo = kMinTextFontSize;
    var hi = clampedHeight;
    while (
        measureContents(width: clampedWidth, fontSize: hi).height <=
            clampedHeight &&
        hi < kMaxTextFontSize) {
      hi *= 2;
    }
    hi = hi.clamp(kMinTextFontSize, kMaxTextFontSize);

    for (var i = 0; i < 40; i++) {
      if (hi - lo < 0.25) {
        break;
      }
      final mid = (lo + hi) / 2;
      if (measureContents(width: clampedWidth, fontSize: mid).height <=
          clampedHeight) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  FeatureKindText fittedToBounds({
    required double width,
    required double height,
  }) {
    final clampedWidth = width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : width;
    final clampedHeight = height < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : height;
    return FeatureKindText(
      contents,
      fontSize: fontSizeFillingBounds(
        width: clampedWidth,
        height: clampedHeight,
      ),
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Sets [feature] to [fontSize] and a height measured from [contents].
  void applySizeFromFontSize(
    Feature feature, {
    required double width,
    required Offset origin,
    required double fontSize,
  }) {
    feature.origin = origin;
    feature.size = measureContents(width: width, fontSize: fontSize);
    feature.kind = FeatureKindText(
      contents,
      fontSize: fontSize,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  void applyBounds(Feature feature, Rect bounds) {
    final clampedWidth = bounds.width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : bounds.width;
    final clampedHeight = bounds.height < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : bounds.height;
    feature.origin = bounds.topLeft;
    feature.size = Size(clampedWidth, clampedHeight);
    feature.kind = fittedToBounds(width: clampedWidth, height: clampedHeight);
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

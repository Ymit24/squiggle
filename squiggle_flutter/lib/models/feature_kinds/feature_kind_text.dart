part of 'feature_kind.dart';

const kMinTextFontSize = 1.0;
const kMaxTextFontSize = 1000.0;

mixin FeatureKindWithLabel {
  String? get label;
  set label(String? value);

  double get fontSize;
  TextHorizontalAlignment get horizontalAlignment;
  TextVerticalAlignment get verticalAlignment;

  Color get strokeColor;
  Color get fillColor;
  double get strokeWidth;

  void paintLabel(
    Feature feature,
    Canvas canvas,
    ImageRepository imageRepository, {
    void Function(Canvas, Feature, Offset, Paragraph)? beforeDraw,
  }) {
    if (label != null && label!.isEmpty) return;

    final worldBounds = feature.localBounds();
    final paragraphStyle = _paragraphStyle(fontSize);

    final strokeParagraph = _layoutParagraph(
      paragraphStyle: paragraphStyle,
      textStyle: ui.TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor,
        fontSize: fontSize,
      ),
      width: worldBounds.width,
    );
    final fillParagraph = _layoutParagraph(
      paragraphStyle: paragraphStyle,
      textStyle: ui.TextStyle(color: fillColor, fontSize: fontSize),
      width: worldBounds.width,
    );

    final position = getLabelPosition(worldBounds, fillParagraph);

    beforeDraw?.call(canvas, feature, position, fillParagraph);
    canvas.drawParagraph(strokeParagraph, position);
    canvas.drawParagraph(fillParagraph, position);
  }

  Offset getLabelPosition(Rect worldBounds, Paragraph fillParagraph) =>
      textOriginInBounds(
        bounds: worldBounds,
        textHeight: fillParagraph.height,
        verticalAlignment: verticalAlignment,
      );

  ui.ParagraphStyle _paragraphStyle(double fontSize) => ui.ParagraphStyle(
    textAlign: horizontalAlignment.textAlign,
    fontSize: fontSize,
    textDirection: TextDirection.ltr,
  );

  ui.Paragraph _layoutParagraph({
    required ui.ParagraphStyle paragraphStyle,
    required ui.TextStyle textStyle,
    required double width,
  }) {
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(label ?? "");
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }
}

final class FeatureKindText extends FeatureKind with FeatureKindWithLabel {
  FeatureKindText(
    this.contents, {
    this.fontSize = defaultFontSize,
    this.horizontalAlignment = TextHorizontalAlignment.left,
    this.verticalAlignment = TextVerticalAlignment.top,
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

  factory FeatureKindText.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindText(
        content['contents'] as String,
        fontSize: _doubleFromDataModel(content, 'fontSize'),
        horizontalAlignment: TextHorizontalAlignment.values.byName(
          content['horizontalAlignment'] as String,
        ),
        verticalAlignment: TextVerticalAlignment.values.byName(
          content['verticalAlignment'] as String,
        ),
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() {
    return {
      'type': 'text',
      'contents': contents,
      'fontSize': fontSize,
      'horizontalAlignment': horizontalAlignment.name,
      'verticalAlignment': verticalAlignment.name,
      'strokeColor': strokeColor.toARGB32(),
      'fillColor': fillColor.toARGB32(),
      'strokeWidth': strokeWidth,
    };
  }

  String contents;

  @override
  String? get label => contents;

  @override
  set label(String? value) {
    contents = value ?? "";
  }

  @override
  final double fontSize;

  @override
  final TextHorizontalAlignment horizontalAlignment;

  @override
  final TextVerticalAlignment verticalAlignment;

  ui.ParagraphStyle _paragraphStyle(double fontSize) => ui.ParagraphStyle(
    textAlign: horizontalAlignment.textAlign,
    fontSize: fontSize,
    textDirection: TextDirection.ltr,
  );

  Size measureContents({required double width, required double fontSize}) {
    final clampedWidth = width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : width;
    if (contents.isEmpty) {
      return Size(clampedWidth, fontSize);
    }

    final builder = ui.ParagraphBuilder(_paragraphStyle(fontSize))
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
        ).height >
        clampedHeight) {
      return kMinTextFontSize;
    }

    var lo = kMinTextFontSize;
    var hi = clampedHeight;
    while (measureContents(width: clampedWidth, fontSize: hi).height <=
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
      horizontalAlignment: horizontalAlignment,
      verticalAlignment: verticalAlignment,
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
      horizontalAlignment: horizontalAlignment,
      verticalAlignment: verticalAlignment,
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

  ui.Paragraph _layoutParagraph({
    required ui.ParagraphStyle paragraphStyle,
    required ui.TextStyle textStyle,
    required double width,
  }) {
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(contents);
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    paintLabel(feature, canvas, imageRepository);
  }
}

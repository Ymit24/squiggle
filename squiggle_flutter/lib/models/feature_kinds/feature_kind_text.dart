part of 'feature_kind.dart';

final class FeatureKindText extends FeatureKind
    with StrokeColorCapable, LabelCapable {
  FeatureKindText(
    this.label, {
    this.sizing = TextSizing.auto,
    this.fontSize = defaultFontSize,
    this.horizontalAlignment = TextHorizontalAlignment.left,
    this.strokeColor = defaultFeatureStrokeColor,
  });

  factory FeatureKindText.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindText(
        content['contents'] as String,
        sizing: decodeStyleEnum(content['sizing'], TextSizing.values),
        fontSize: _doubleFromDataModel(content, 'fontSize'),
        horizontalAlignment: decodeStyleEnum(
          content['horizontalAlignment'],
          TextHorizontalAlignment.values,
        ),
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
      );

  @override
  Color strokeColor;

  @override
  String label;

  TextSizing sizing;
  double fontSize;
  TextHorizontalAlignment horizontalAlignment;

  /// Fraction of the box width that stays put when auto-sized text grows:
  /// left-aligned text grows rightward, centered text both ways, and so on.
  double get anchorFraction => switch (horizontalAlignment) {
    TextHorizontalAlignment.left => 0,
    TextHorizontalAlignment.center => 0.5,
    TextHorizontalAlignment.right => 1,
  };

  /// Narrowest wrap width: one em, so a column is never one glyph per line.
  double get minWrapWidth => fontSize;

  @override
  Map<String, dynamic> toDataModel() {
    return {
      'type': 'text',
      'contents': label,
      'sizing': sizing.name,
      'fontSize': fontSize,
      'horizontalAlignment': horizontalAlignment.name,
      'strokeColor': strokeColor.toARGB32(),
    };
  }

  @override
  FeatureKindText clone() => FeatureKindText(
    label,
    sizing: sizing,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
    strokeColor: strokeColor,
  );

  /// Size of [text] at [fontSize], wrapped at [width] or, when null, not
  /// wrapped at all.
  Size measureContents({
    required double fontSize,
    double? width,
    String? text,
  }) {
    final contents = (text ?? label).isEmpty ? ' ' : (text ?? label);
    return width == null
        ? text_painter.measureTextIntrinsic(
            contents,
            fontSize: fontSize,
            horizontalAlignment: horizontalAlignment,
          )
        : text_painter.measureText(
            contents,
            width: width,
            fontSize: fontSize,
            horizontalAlignment: horizontalAlignment,
          );
  }

  /// Where [feature] sits once its box matches [contents] at [fontSize].
  ///
  /// Auto-sized text keeps its alignment point fixed as the width changes;
  /// fixed-width text keeps its width and only its height follows.
  Rect fittedBounds(Feature feature, {String? contents}) {
    final current = feature.localBounds();
    final size = measureContents(
      text: contents,
      fontSize: fontSize,
      width: sizing == TextSizing.fixedWidth ? current.width : null,
    );
    return Rect.fromLTWH(
      current.left + (current.width - size.width) * anchorFraction,
      current.top,
      size.width,
      size.height,
    );
  }

  @override
  void setLabel(Feature feature, String value) {
    label = value;
    feature.setBounds(fittedBounds(feature));
  }

  @override
  void refit(Feature feature) => feature.setBounds(fittedBounds(feature));

  /// Corner drags and programmatic resizes scale the font with the box. Side
  /// drags only change the wrap width, which makes the text fixed-width. Height
  /// always follows the contents, so top and bottom handles are not offered.
  @override
  void applyBounds(Feature feature, Rect bounds, {ResizeDrag? drag}) {
    final current = feature.localBounds();
    final Size size;
    if (drag != null && !drag.isCorner) {
      sizing = TextSizing.fixedWidth;
      size = measureContents(
        fontSize: fontSize,
        width: math.max(bounds.width, minWrapWidth),
      );
    } else {
      final baseFontSize = fontSize;
      fontSize = (baseFontSize * _projectedScale(bounds.size, current.size))
          .clamp(text_painter.kMinTextFontSize, text_painter.kMaxTextFontSize);
      size = measureContents(
        fontSize: fontSize,
        width: sizing == TextSizing.fixedWidth
            ? current.width * fontSize / baseFontSize
            : null,
      );
    }
    feature.setBounds(_placed(size, current, bounds, drag));
  }

  @override
  bool get supportsVerticalResize => false;

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    if (feature.hideLabel) return;
    labelLayout(feature).paint(canvas, label, clipToBounds: false);
  }

  @override
  LabelLayout labelLayout(Feature feature) => _layoutIn(feature.localBounds());

  /// The layout [feature] would have if its label were [contents]; the inline
  /// editor follows it as the draft grows.
  LabelLayout labelLayoutFor(Feature feature, String contents) =>
      _layoutIn(fittedBounds(feature, contents: contents));

  @override
  Iterable<InspectorField> buildInspectorFields() {
    return [
      InspectorColorField(
        fieldKey: 'strokeColor',
        label: 'Stroke Color',
        value: strokeColor,
        onColorChanged: (color) {
          strokeColor = color;
        },
      ),
      InspectorHorizontalTextAlignmentField(
        fieldKey: 'horizontalAlignment',
        label: 'Horizontal Alignment',
        value: horizontalAlignment,
        onTextAlignChanged: (value) {
          horizontalAlignment = value;
        },
      ),
      InspectorTextSizingField(
        fieldKey: 'sizing',
        label: 'Sizing',
        value: sizing,
        onSizingChanged: (value) {
          sizing = value;
        },
      ),
      InspectorFontSizeField(
        fieldKey: 'fontSize',
        label: 'Font Size',
        value: fontSize,
        onFontSizeChanged: (value) {
          fontSize = value;
        },
      ),
    ];
  }

  /// Where a box of [size] goes so that [drag]'s fixed point of [from] stays
  /// put; without a drag it takes the top-left of [to].
  static Rect _placed(Size size, Rect from, Rect to, ResizeDrag? drag) {
    if (drag == null) return to.topLeft & size;
    final fixed = drag.fixedPoint;
    final anchor = fixed.withinRect(from);
    return Rect.fromLTWH(
      anchor.dx - size.width * (fixed.x + 1) / 2,
      drag.isCorner ? anchor.dy - size.height * (fixed.y + 1) / 2 : from.top,
      size.width,
      size.height,
    );
  }

  /// Scale of [base] that [target] corresponds to, taken by projecting the
  /// target size onto the base's diagonal. Unlike picking the larger of the
  /// width and height ratios, it has no switch-over point where it jumps.
  static double _projectedScale(Size target, Size base) {
    final diagonalSquared = base.width * base.width + base.height * base.height;
    if (diagonalSquared == 0) return 1;
    return (target.width * base.width + target.height * base.height) /
        diagonalSquared;
  }

  LabelLayout _layoutIn(Rect bounds) => LabelLayout(
    bounds: bounds,
    fontSize: fontSize,
    color: strokeColor,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: TextVerticalAlignment.top,
  );
}

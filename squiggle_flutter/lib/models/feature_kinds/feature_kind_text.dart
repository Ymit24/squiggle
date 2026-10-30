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
    _refit(feature);
  }

  /// Drops a fixed width so the box hugs its contents again.
  void makeAutoWidth(Feature feature) {
    sizing = TextSizing.auto;
    _refit(feature);
  }

  /// Height always follows the contents, so a resize that only changes the
  /// width reflows the text at that width, making it fixed-width. Any other
  /// resize scales the font with the box.
  @override
  void applyBounds(Feature feature, Rect bounds) {
    final current = feature.localBounds();
    final size = _resizedSize(bounds, current);
    feature.setBounds(
      Rect.fromLTWH(
        _alignedStart(
          bounds.left,
          bounds.right,
          current.left,
          current.right,
          size.width,
        ),
        _alignedStart(
          bounds.top,
          bounds.bottom,
          current.top,
          current.bottom,
          size.height,
        ),
        size.width,
        size.height,
      ),
    );
  }

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
  Iterable<InspectorField> buildInspectorFields({Feature? feature}) {
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
          _refit(feature);
        },
      ),
      InspectorFontSizeField(
        fieldKey: 'fontSize',
        label: 'Font Size',
        value: fontSize,
        onFontSizeChanged: (value) {
          fontSize = value;
          _refit(feature);
        },
      ),
    ];
  }

  /// Start of a box of [extent] placed within [toStart]..[toEnd] on one axis.
  /// It keeps to whichever edge of the resized range still touches an edge of
  /// the original [fromStart]..[fromEnd], i.e. the side that stayed put, so
  /// the text follows the cursor; with neither, as when resizing from the
  /// centre, it is centred.
  static double _alignedStart(
    double toStart,
    double toEnd,
    double fromStart,
    double fromEnd,
    double extent,
  ) {
    bool touches(double edge) =>
        _isClose(edge, fromStart) || _isClose(edge, fromEnd);
    if (touches(toStart)) return toStart;
    if (touches(toEnd)) return toEnd - extent;
    return (toStart + toEnd - extent) / 2;
  }

  static bool _isWidthOnly(Rect bounds, Rect current) =>
      _isClose(bounds.height, current.height) &&
      !_isClose(bounds.width, current.width);

  static bool _isClose(double a, double b) => (a - b).abs() < 1e-6;

  /// Scale of [base] that [target] corresponds to, taken by projecting the
  /// target size onto the base's diagonal. Unlike picking the larger of the
  /// width and height ratios, it has no switch-over point where it jumps.
  static double _projectedScale(Size target, Size base) {
    final diagonalSquared = base.width * base.width + base.height * base.height;
    if (diagonalSquared == 0) return 1;
    return (target.width * base.width + target.height * base.height) /
        diagonalSquared;
  }

  Size _resizedSize(Rect bounds, Rect current) {
    if (_isWidthOnly(bounds, current)) {
      sizing = TextSizing.fixedWidth;
      return measureContents(
        fontSize: fontSize,
        width: math.max(bounds.width, minWrapWidth),
      );
    }
    final baseFontSize = fontSize;
    fontSize = (baseFontSize * _projectedScale(bounds.size, current.size))
        .clamp(text_painter.kMinTextFontSize, text_painter.kMaxTextFontSize);
    return measureContents(
      fontSize: fontSize,
      width: sizing == TextSizing.fixedWidth
          ? current.width * fontSize / baseFontSize
          : null,
    );
  }

  void _refit(Feature? feature) {
    if (feature != null) feature.setBounds(fittedBounds(feature));
  }

  LabelLayout _layoutIn(Rect bounds) => LabelLayout(
    bounds: bounds,
    fontSize: fontSize,
    color: strokeColor,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: TextVerticalAlignment.top,
  );
}

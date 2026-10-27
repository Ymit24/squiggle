part of 'feature_kind.dart';

final class FeatureKindText extends FeatureKind
    with StrokeColorCapable, LabelCapable {
  FeatureKindText(
    this.label, {
    this.sizing = TextSizing.auto,
    this.fontSize = defaultFontSize,
    this.horizontalAlignment = TextHorizontalAlignment.left,
    this.verticalAlignment = TextVerticalAlignment.top,
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
        verticalAlignment: decodeStyleEnum(
          content['verticalAlignment'],
          TextVerticalAlignment.values,
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
  TextVerticalAlignment verticalAlignment;

  /// Fraction of the box width that stays put when auto-sized text grows:
  /// left-aligned text grows rightward, centered text both ways, and so on.
  double get anchorFraction => switch (horizontalAlignment) {
    TextHorizontalAlignment.left => 0,
    TextHorizontalAlignment.center => 0.5,
    TextHorizontalAlignment.right => 1,
  };

  @override
  Map<String, dynamic> toDataModel() {
    return {
      'type': 'text',
      'contents': label,
      'sizing': sizing.name,
      'fontSize': fontSize,
      'horizontalAlignment': horizontalAlignment.name,
      'verticalAlignment': verticalAlignment.name,
      'strokeColor': strokeColor.toARGB32(),
    };
  }

  @override
  FeatureKindText clone() => FeatureKindText(
    label,
    sizing: sizing,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: verticalAlignment,
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
  Rect fittedBounds(Feature feature, {String? contents, double? fontSize}) {
    final current = feature.localBounds();
    final size = measureContents(
      text: contents,
      fontSize: fontSize ?? this.fontSize,
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

  /// Scales for a group resize: the font follows the box's overall size change.
  @override
  void applyBounds(Feature feature, Rect bounds) {
    final current = feature.localBounds();
    final scale = _projectedScale(bounds.size, current.size);
    final scaled = _scaledFrom(fontSize, current, scale);
    fontSize = scaled.fontSize;
    feature.setBounds(
      Rect.fromLTWH(
        bounds.left,
        bounds.top,
        scaled.size.width,
        scaled.size.height,
      ),
    );
  }

  /// Corner handles scale the text about the opposite corner. Left and right
  /// handles only change the wrap width, which makes the text fixed-width.
  /// Top and bottom handles are not offered, since height follows the text.
  @override
  void applyHandleResize(
    Feature feature,
    Feature initial,
    Rect bounds,
    SelectionResizeHandle handle,
  ) {
    final start = (initial.kind as FeatureKindText);
    final startBounds = initial.localBounds();
    if (handle.isCorner) {
      final scaled = start._scaledFrom(
        start.fontSize,
        startBounds,
        _projectedScale(bounds.size, startBounds.size),
      );
      fontSize = scaled.fontSize;
      feature.setBounds(
        Rect.fromLTWH(
          handle.movesLeft ? bounds.right - scaled.size.width : bounds.left,
          handle.movesTop ? bounds.bottom - scaled.size.height : bounds.top,
          scaled.size.width,
          scaled.size.height,
        ),
      );
    } else if (handle == SelectionResizeHandle.left ||
        handle == SelectionResizeHandle.right) {
      sizing = TextSizing.fixedWidth;
      fontSize = start.fontSize;
      final width = math.max(bounds.width, fontSize);
      final size = measureContents(fontSize: fontSize, width: width);
      feature.setBounds(
        Rect.fromLTWH(
          handle.movesLeft ? bounds.right - width : bounds.left,
          startBounds.top,
          width,
          size.height,
        ),
      );
    }
  }

  @override
  bool supportsResizeHandle(SelectionResizeHandle handle) =>
      handle != SelectionResizeHandle.top &&
      handle != SelectionResizeHandle.bottom;

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
      InspectorVerticalTextAlignmentField(
        fieldKey: 'verticalAlignment',
        label: 'Vertical Alignment',
        value: verticalAlignment,
        onTextAlignChanged: (value) {
          verticalAlignment = value;
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

  /// Font size and box size after scaling the text laid out in [base] at
  /// [baseFontSize] by [scale]; the font is clamped to its limits and a fixed
  /// width follows the font actually reached.
  ({double fontSize, Size size}) _scaledFrom(
    double baseFontSize,
    Rect base,
    double scale,
  ) {
    final scaledFont = (baseFontSize * scale).clamp(
      text_painter.kMinTextFontSize,
      text_painter.kMaxTextFontSize,
    );
    return (
      fontSize: scaledFont,
      size: measureContents(
        fontSize: scaledFont,
        width: sizing == TextSizing.fixedWidth
            ? base.width * scaledFont / baseFontSize
            : null,
      ),
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
    verticalAlignment: verticalAlignment,
  );
}

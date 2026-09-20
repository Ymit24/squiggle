part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind
    with
        StrokeColorCapable,
        FillColorCapable,
        StrokeWidthCapable,
        LabelCapable {
  FeatureKindRectangle({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    this.strokeWidth = defaultStrokeWidth,
    this.label = '',
  });

  @override
  Color strokeColor;

  @override
  Color fillColor;

  @override
  double strokeWidth;

  @override
  String label;

  factory FeatureKindRectangle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindRectangle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        label: content['label'],
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'rectangle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'label': label,
  };

  @override
  FeatureKindRectangle clone() => FeatureKindRectangle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    label: label,
  );

  @override
  void setLabel(Feature feature, String value) {
    label = value;
    _growHeightToFitLabel(
      feature,
      value,
      _paddedLabelBounds(feature.localBounds()),
    );
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.localBounds();
    canvas.drawRect(bounds, Paint()..color = fillColor);
    canvas.drawRect(
      bounds,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    text_painter.paintText(
      canvas,
      label,
      _paddedLabelBounds(bounds),
      fontSize: _labelFontSize,
      fillColor: Color.fromARGB(255, 255, 255, 255),
    );
  }

  @override
  Iterable<InspectorCapability> buildInspectorCapabilities() {
    return [
      InspectorColorCapability(
        fieldKey: 'strokeColor',
        label: 'Stroke Color',
        value: strokeColor,
        onColorChanged: (color) {
          strokeColor = color;
        },
      ),
      InspectorColorCapability(
        fieldKey: 'fillColor',
        label: 'Fill Color',
        value: fillColor,
        onColorChanged: (color) {
          fillColor = color;
        },
      ),
      InspectorWidthCapability(
        fieldKey: 'strokeWidth',
        label: 'Stroke Width',
        value: strokeWidth,
        onWidthChanged: (width) {
          strokeWidth = width;
        },
      ),
    ];
  }
}

abstract class InspectorCapability<T> {
  String fieldKey;
  String label;

  List<T> values;
  List<Function(T)> callbacks;

  InspectorCapability({
    required this.fieldKey,
    required this.label,
    required this.values,
    required this.callbacks,
  });

  T get activeValue => values.first;

  bool get isMixed => values.toSet().length > 1;

  void merge(InspectorCapability<T> other) {
    values.addAll(other.values);
    callbacks.addAll(other.callbacks);
  }

  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(T) onUpdate,
  );

  void apply(T value) {
    for (final callback in callbacks) {
      callback(value);
    }
  }
}

class InspectorColorCapability extends InspectorCapability<Color> {
  InspectorColorCapability({
    required super.fieldKey,
    required super.label,
    required Color value,
    required ValueChanged<Color> onColorChanged,
  }) : super(values: [value], callbacks: [onColorChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(Color) onUpdate,
  ) {
    final activeStrokePresetIndex = stylePresets.indexOf(
      stylePresets.firstWhere((preset) => preset.strokeColor == activeValue),
    );
    return InspectorCapabilityFieldShell(
      label: label,
      child: ColorRow(
        presets: stylePresets.map((preset) => preset.strokeColor).toList(),
        activePresetIndex: isMixed ? null : activeStrokePresetIndex,
        noneEnabled: true,
        onPresetSelected: (index) {
          final color = stylePresets[index].strokeColor;
          onUpdate(color);
        },
      ),
    );
  }
}

class InspectorVerticalTextAlignmentCapability
    extends InspectorCapability<TextVerticalAlignment> {
  InspectorVerticalTextAlignmentCapability({
    required super.fieldKey,
    required super.label,
    required TextVerticalAlignment value,
    required ValueChanged<TextVerticalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(TextVerticalAlignment) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: TextVerticalAlignmentSelector(
        activeAlignment: activeValue,
        isMixed: isMixed,
        onAlignmentSelected: onUpdate,
      ),
    );
  }
}

class InspectorHorizontalTextAlignmentCapability
    extends InspectorCapability<TextHorizontalAlignment> {
  InspectorHorizontalTextAlignmentCapability({
    required super.fieldKey,
    required super.label,
    required TextHorizontalAlignment value,
    required ValueChanged<TextHorizontalAlignment> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(TextHorizontalAlignment) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: TextHorizontalAlignmentSelector(
        activeAlignment: activeValue,
        isMixed: isMixed,
        onAlignmentSelected: onUpdate,
      ),
    );
  }
}

class InspectorWidthCapability extends InspectorCapability<double> {
  InspectorWidthCapability({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onWidthChanged,
  }) : super(values: [value], callbacks: [onWidthChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: StrokeWidthSelector(
        activePreset: StrokeWidthPreset.fromWidth(activeValue),
        isMixed: isMixed,
        onPresetSelected: (StrokeWidthPreset value) {
          onUpdate(value.width);
        },
      ),
    );
  }
}

class InspectorFontSizeCapability extends InspectorCapability<double> {
  InspectorFontSizeCapability({
    required super.fieldKey,
    required super.label,
    required double value,
    required ValueChanged<double> onFontSizeChanged,
  }) : super(values: [value], callbacks: [onFontSizeChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(double) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: FontSizeSelector(
        activePreset: FontSizePreset.fromSize(activeValue),
        isMixed: isMixed,
        onPresetSelected: (FontSizePreset value) {
          onUpdate(value.size);
        },
      ),
    );
  }
}

class InspectorEndCapCapability extends InspectorCapability<LineEndCap> {
  InspectorEndCapCapability({
    required super.fieldKey,
    required super.label,
    required this.isStart,
    required LineEndCap value,
    required ValueChanged<LineEndCap> onEndCapChanged,
  }) : super(values: [value], callbacks: [onEndCapChanged]);

  final bool isStart;

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(LineEndCap) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: LineEndCapSelector(
        activeEndCap: activeValue,
        isMixed: isMixed,
        isStart: isStart,
        onEndCapSelected: (LineEndCap value) {
          onUpdate(value);
        },
      ),
    );
  }
}

Iterable<InspectorCapabilityFieldShell> buildInspectorPanel(
  BuildContext context,
  EditorContext editorContext,
  List<Feature> features,
) {
  final capabilities = features.expand(
    (feature) => feature.kind.buildInspectorCapabilities(),
  );

  final callbacksByFieldKey = <String, InspectorCapability>{};

  for (final capability in capabilities) {
    final fieldKey = capability.fieldKey;
    if (callbacksByFieldKey.containsKey(fieldKey)) {
      callbacksByFieldKey[fieldKey]!.merge(capability);
    } else {
      callbacksByFieldKey[fieldKey] = capability;
    }
  }

  return callbacksByFieldKey.values.map(
    (capability) => capability.build(context, (result) {
      editorContext.history.run("Inspector Update", (transaction) {
        transaction.watch(features);
        capability.apply(result);
      });
    }),
  );
}

/// Common look and feel for inspector capabilities.
class InspectorCapabilityFieldShell extends StatelessWidget {
  final Widget child;
  final String label;

  const InspectorCapabilityFieldShell({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SectionLabel(label), child],
    );
  }
}

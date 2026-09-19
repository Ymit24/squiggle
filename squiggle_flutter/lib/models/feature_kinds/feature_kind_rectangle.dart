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

  void merge(InspectorCapability<T> other) {
    values.addAll(other.values);
    callbacks.addAll(other.callbacks);
  }

  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(Function()) onUpdate,
  );
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
    void Function(Function()) onUpdate,
  ) {
    final isStrokeMixed = values.toSet().length > 1;
    final activeStrokePresetIndex = stylePresets.indexOf(
      stylePresets.firstWhere((preset) => preset.strokeColor == values.first),
    );
    return InspectorCapabilityFieldShell(
      label: label,
      child: ColorRow(
        presets: stylePresets.map((preset) => preset.strokeColor).toList(),
        activePresetIndex: isStrokeMixed ? null : activeStrokePresetIndex,
        noneEnabled: true,
        onPresetSelected: (index) {
          print("Selected color preset: $index");
          onUpdate(() {
            final color = stylePresets[index].strokeColor;
            for (final callback in callbacks) {
              callback(color);
            }
          });
        },
      ),
    );
  }
}

class InspectorVerticalTextAlignmentCapability
    extends InspectorCapability<TextAlignVertical> {
  InspectorVerticalTextAlignmentCapability({
    required super.fieldKey,
    required super.label,
    required TextAlignVertical value,
    required ValueChanged<TextAlignVertical> onTextAlignChanged,
  }) : super(values: [value], callbacks: [onTextAlignChanged]);

  @override
  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(Function()) onUpdate,
  ) {
    return InspectorCapabilityFieldShell(
      label: label,
      child: Text("Text align changer!"),
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

  void onUpdate(void Function() cb) {
    editorContext.history.run("Inspector Update", (transaction) {
      transaction.watch(features);

      cb();
    });
  }

  return callbacksByFieldKey.values.map(
    (capability) => capability.build(context, onUpdate),
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

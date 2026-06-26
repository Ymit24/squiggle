import 'package:flutter/foundation.dart';

const kFloatingPanelRadius = 12.0;
const kTextEditPanelRadius = 8.0;
const kButtonRadius = 6.0;
const kInputRadius = 6.0;
const kSwatchRadius = 5.0;

/// Border radius tokens for UI chrome.
@immutable
class SquiggleRadii {
  const SquiggleRadii({
    required this.floatingPanel,
    required this.textEditPanel,
    required this.button,
    required this.input,
    required this.swatch,
  });

  final double floatingPanel;
  final double textEditPanel;
  final double button;
  final double input;
  final double swatch;

  static const standard = SquiggleRadii(
    floatingPanel: kFloatingPanelRadius,
    textEditPanel: kTextEditPanelRadius,
    button: kButtonRadius,
    input: kInputRadius,
    swatch: kSwatchRadius,
  );

  SquiggleRadii copyWith({
    double? floatingPanel,
    double? textEditPanel,
    double? button,
    double? input,
    double? swatch,
  }) {
    return SquiggleRadii(
      floatingPanel: floatingPanel ?? this.floatingPanel,
      textEditPanel: textEditPanel ?? this.textEditPanel,
      button: button ?? this.button,
      input: input ?? this.input,
      swatch: swatch ?? this.swatch,
    );
  }

  SquiggleRadii lerp(SquiggleRadii other, double t) {
    return SquiggleRadii(
      floatingPanel: _lerpDouble(floatingPanel, other.floatingPanel, t),
      textEditPanel: _lerpDouble(textEditPanel, other.textEditPanel, t),
      button: _lerpDouble(button, other.button, t),
      input: _lerpDouble(input, other.input, t),
      swatch: _lerpDouble(swatch, other.swatch, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

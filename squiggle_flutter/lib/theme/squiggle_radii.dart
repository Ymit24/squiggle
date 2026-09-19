import 'package:flutter/foundation.dart';

const kFloatingPanelRadius = 12.0;
const kTextEditPanelRadius = 8.0;
const kButtonRadius = 6.0;
const kInputRadius = 6.0;
const kSwatchRadius = 5.0;
const kControlRadius = 10.0;
const kActionRadius = 9.0;
const kCardRadius = 16.0;
const kPillRadius = 999.0;

/// Border radius tokens for UI chrome.
@immutable
class SquiggleRadii {
  const SquiggleRadii({
    required this.floatingPanel,
    required this.textEditPanel,
    required this.button,
    required this.input,
    required this.swatch,
    required this.control,
    required this.action,
    required this.card,
    required this.pill,
  });

  final double floatingPanel;
  final double textEditPanel;
  final double button;
  final double input;
  final double swatch;
  final double control;
  final double action;
  final double card;
  final double pill;

  static const standard = SquiggleRadii(
    floatingPanel: kFloatingPanelRadius,
    textEditPanel: kTextEditPanelRadius,
    button: kButtonRadius,
    input: kInputRadius,
    swatch: kSwatchRadius,
    control: kControlRadius,
    action: kActionRadius,
    card: kCardRadius,
    pill: kPillRadius,
  );

  SquiggleRadii copyWith({
    double? floatingPanel,
    double? textEditPanel,
    double? button,
    double? input,
    double? swatch,
    double? control,
    double? action,
    double? card,
    double? pill,
  }) {
    return SquiggleRadii(
      floatingPanel: floatingPanel ?? this.floatingPanel,
      textEditPanel: textEditPanel ?? this.textEditPanel,
      button: button ?? this.button,
      input: input ?? this.input,
      swatch: swatch ?? this.swatch,
      control: control ?? this.control,
      action: action ?? this.action,
      card: card ?? this.card,
      pill: pill ?? this.pill,
    );
  }

  SquiggleRadii lerp(SquiggleRadii other, double t) {
    return SquiggleRadii(
      floatingPanel: _lerpDouble(floatingPanel, other.floatingPanel, t),
      textEditPanel: _lerpDouble(textEditPanel, other.textEditPanel, t),
      button: _lerpDouble(button, other.button, t),
      input: _lerpDouble(input, other.input, t),
      swatch: _lerpDouble(swatch, other.swatch, t),
      control: _lerpDouble(control, other.control, t),
      action: _lerpDouble(action, other.action, t),
      card: _lerpDouble(card, other.card, t),
      pill: _lerpDouble(pill, other.pill, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

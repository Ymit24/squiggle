import 'package:flutter/foundation.dart';

const kOverlayTop = 20.0;
const kOverlaySide = 20.0;
const kToolbarPadding = 4.0;
const kToolbarGap = 2.0;
const kToolbarButtonSize = 36.0;
const kToolbarIconSize = 20.0;
const kToolbarDividerHeight = 20.0;
const kPanelPadding = 12.0;
const kPanelSectionSpacing = 12.0;
const kPanelLabelSpacing = 8.0;
const kSwatchSize = 26.0;
const kSwatchGap = 6.0;
const kSwatchBorderWidth = 2.0;
const kSwatchColumns = 4;
const kTextEditPanelPadding = 12.0;
const kTextEditButtonSpacing = 8.0;
const kTextEditButtonHorizontalPadding = 12.0;
const kTextEditButtonVerticalPadding = 6.0;

const kSwatchGridWidth =
    kSwatchColumns * kSwatchSize + (kSwatchColumns - 1) * kSwatchGap;

/// Layout and sizing tokens for UI chrome.
@immutable
class SquiggleSpacing {
  const SquiggleSpacing({
    required this.overlayTop,
    required this.overlaySide,
    required this.toolbarPadding,
    required this.toolbarGap,
    required this.toolbarButtonSize,
    required this.toolbarIconSize,
    required this.toolbarDividerHeight,
    required this.panelPadding,
    required this.panelSectionSpacing,
    required this.panelLabelSpacing,
    required this.swatchSize,
    required this.swatchGap,
    required this.swatchBorderWidth,
    required this.textEditPanelPadding,
    required this.textEditButtonSpacing,
    required this.textEditButtonHorizontalPadding,
    required this.textEditButtonVerticalPadding,
  });

  final double overlayTop;
  final double overlaySide;
  final double toolbarPadding;
  final double toolbarGap;
  final double toolbarButtonSize;
  final double toolbarIconSize;
  final double toolbarDividerHeight;
  final double panelPadding;
  final double panelSectionSpacing;
  final double panelLabelSpacing;
  final double swatchSize;
  final double swatchGap;
  final double swatchBorderWidth;
  final double textEditPanelPadding;
  final double textEditButtonSpacing;
  final double textEditButtonHorizontalPadding;
  final double textEditButtonVerticalPadding;

  int get swatchColumns => kSwatchColumns;

  double get swatchGridWidth => kSwatchGridWidth;

  static const standard = SquiggleSpacing(
    overlayTop: kOverlayTop,
    overlaySide: kOverlaySide,
    toolbarPadding: kToolbarPadding,
    toolbarGap: kToolbarGap,
    toolbarButtonSize: kToolbarButtonSize,
    toolbarIconSize: kToolbarIconSize,
    toolbarDividerHeight: kToolbarDividerHeight,
    panelPadding: kPanelPadding,
    panelSectionSpacing: kPanelSectionSpacing,
    panelLabelSpacing: kPanelLabelSpacing,
    swatchSize: kSwatchSize,
    swatchGap: kSwatchGap,
    swatchBorderWidth: kSwatchBorderWidth,
    textEditPanelPadding: kTextEditPanelPadding,
    textEditButtonSpacing: kTextEditButtonSpacing,
    textEditButtonHorizontalPadding: kTextEditButtonHorizontalPadding,
    textEditButtonVerticalPadding: kTextEditButtonVerticalPadding,
  );

  SquiggleSpacing copyWith({
    double? overlayTop,
    double? overlaySide,
    double? toolbarPadding,
    double? toolbarGap,
    double? toolbarButtonSize,
    double? toolbarIconSize,
    double? toolbarDividerHeight,
    double? panelPadding,
    double? panelSectionSpacing,
    double? panelLabelSpacing,
    double? swatchSize,
    double? swatchGap,
    double? swatchBorderWidth,
    double? textEditPanelPadding,
    double? textEditButtonSpacing,
    double? textEditButtonHorizontalPadding,
    double? textEditButtonVerticalPadding,
  }) {
    return SquiggleSpacing(
      overlayTop: overlayTop ?? this.overlayTop,
      overlaySide: overlaySide ?? this.overlaySide,
      toolbarPadding: toolbarPadding ?? this.toolbarPadding,
      toolbarGap: toolbarGap ?? this.toolbarGap,
      toolbarButtonSize: toolbarButtonSize ?? this.toolbarButtonSize,
      toolbarIconSize: toolbarIconSize ?? this.toolbarIconSize,
      toolbarDividerHeight: toolbarDividerHeight ?? this.toolbarDividerHeight,
      panelPadding: panelPadding ?? this.panelPadding,
      panelSectionSpacing: panelSectionSpacing ?? this.panelSectionSpacing,
      panelLabelSpacing: panelLabelSpacing ?? this.panelLabelSpacing,
      swatchSize: swatchSize ?? this.swatchSize,
      swatchGap: swatchGap ?? this.swatchGap,
      swatchBorderWidth: swatchBorderWidth ?? this.swatchBorderWidth,
      textEditPanelPadding: textEditPanelPadding ?? this.textEditPanelPadding,
      textEditButtonSpacing: textEditButtonSpacing ?? this.textEditButtonSpacing,
      textEditButtonHorizontalPadding:
          textEditButtonHorizontalPadding ?? this.textEditButtonHorizontalPadding,
      textEditButtonVerticalPadding:
          textEditButtonVerticalPadding ?? this.textEditButtonVerticalPadding,
    );
  }

  SquiggleSpacing lerp(SquiggleSpacing other, double t) {
    return SquiggleSpacing(
      overlayTop: _lerpDouble(overlayTop, other.overlayTop, t),
      overlaySide: _lerpDouble(overlaySide, other.overlaySide, t),
      toolbarPadding: _lerpDouble(toolbarPadding, other.toolbarPadding, t),
      toolbarGap: _lerpDouble(toolbarGap, other.toolbarGap, t),
      toolbarButtonSize: _lerpDouble(toolbarButtonSize, other.toolbarButtonSize, t),
      toolbarIconSize: _lerpDouble(toolbarIconSize, other.toolbarIconSize, t),
      toolbarDividerHeight:
          _lerpDouble(toolbarDividerHeight, other.toolbarDividerHeight, t),
      panelPadding: _lerpDouble(panelPadding, other.panelPadding, t),
      panelSectionSpacing:
          _lerpDouble(panelSectionSpacing, other.panelSectionSpacing, t),
      panelLabelSpacing: _lerpDouble(panelLabelSpacing, other.panelLabelSpacing, t),
      swatchSize: _lerpDouble(swatchSize, other.swatchSize, t),
      swatchGap: _lerpDouble(swatchGap, other.swatchGap, t),
      swatchBorderWidth: _lerpDouble(swatchBorderWidth, other.swatchBorderWidth, t),
      textEditPanelPadding:
          _lerpDouble(textEditPanelPadding, other.textEditPanelPadding, t),
      textEditButtonSpacing:
          _lerpDouble(textEditButtonSpacing, other.textEditButtonSpacing, t),
      textEditButtonHorizontalPadding: _lerpDouble(
        textEditButtonHorizontalPadding,
        other.textEditButtonHorizontalPadding,
        t,
      ),
      textEditButtonVerticalPadding: _lerpDouble(
        textEditButtonVerticalPadding,
        other.textEditButtonVerticalPadding,
        t,
      ),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

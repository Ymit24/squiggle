import 'package:flutter/widgets.dart';

export 'package:squiggle_flutter/models/font_size_preset.dart';
export 'package:squiggle_flutter/models/stroke_width_preset.dart';

/// Default colors for new canvas features (document content, not UI chrome).
const defaultFeatureStrokeColor = Color(0xFFFFFFFF);
const defaultFeatureFillColor = Color(0xFF000000);
const transparentFillColor = Color(0x00000000);
const transparentStrokeColor = Color(0x00000000);

const defaultNewTextWidth = 200.0;
const defaultNewTextFillColor = defaultFeatureStrokeColor;
const defaultNewTextStrokeColor = transparentStrokeColor;

class StylePreset {
  const StylePreset({required this.strokeColor, required this.fillColor});

  final Color strokeColor;
  final Color fillColor;
}

/// Muted studio palette — strokes are deeper, fills are soft tints within each hue.
const stylePresets = <StylePreset>[
  StylePreset(strokeColor: Color(0xFFC4597A), fillColor: Color(0xFFE8B8C8)),
  StylePreset(strokeColor: Color(0xFF4A72B8), fillColor: Color(0xFFB0C8E8)),
  StylePreset(strokeColor: Color(0xFF3D8C62), fillColor: Color(0xFFA8D8BC)),
  StylePreset(strokeColor: Color(0xFFB8883A), fillColor: Color(0xFFE8D4A0)),
  StylePreset(strokeColor: Color(0xFF7A62A8), fillColor: Color(0xFFC8B8E0)),
  StylePreset(strokeColor: Color(0xFFBC7248), fillColor: Color(0xFFE8C8A8)),
  StylePreset(strokeColor: Color(0xFF3898A0), fillColor: Color(0xFFA0D8E0)),
  StylePreset(strokeColor: Color(0xFF6A7490), fillColor: Color(0xFFB8C0D4)),
  StylePreset(strokeColor: Color(0xFFDCE0EC), fillColor: Color(0xFFEAECF4)),
  StylePreset(strokeColor: Color(0xFF2E3244), fillColor: Color(0xFF5C6278)),
];

int? strokePresetIndexForColor(Color color) {
  for (var i = 0; i < stylePresets.length; i++) {
    if (stylePresets[i].strokeColor == color) {
      return i;
    }
  }
  return null;
}

int? fillPresetIndexForColor(Color color) {
  for (var i = 0; i < stylePresets.length; i++) {
    if (stylePresets[i].fillColor == color) {
      return i;
    }
  }
  return null;
}

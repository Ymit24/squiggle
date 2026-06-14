import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

/// Preview label size in the font-size picker (not the canvas font size).
double _previewFontSize(FontSizePreset preset) => switch (preset) {
  FontSizePreset.small => 8,
  FontSizePreset.medium => 11,
  FontSizePreset.large => 15,
};

class FontSizeSelector extends StatelessWidget {
  const FontSizeSelector({
    super.key,
    required this.activePreset,
    required this.isMixed,
    required this.onPresetSelected,
    this.enabled = true,
  });

  final FontSizePreset? activePreset;
  final bool isMixed;
  final ValueChanged<FontSizePreset> onPresetSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final presets = FontSizePreset.values;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: swatchGap,
      children: [
        for (final preset in presets)
          StyleColorSwatch(
            color: SquiggleColors.base,
            isActive: !isMixed && activePreset == preset,
            enabled: enabled,
            onPressed: () => onPresetSelected(preset),
            overlay: Center(
              child: Text(
                'aA',
                style: TextStyle(
                  color: !isMixed && activePreset == preset
                      ? SquiggleColors.text
                      : SquiggleColors.subtext0,
                  fontSize: _previewFontSize(preset),
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

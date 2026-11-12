import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/metrics.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/style_color_swatch.dart';

/// `#RRGGBB` for [color], ignoring alpha.
String hexColor(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.presets,
    required this.names,
    required this.activePresetIndex,
    required this.noneEnabled,
    required this.onPresetSelected,
  });

  final List<Color> presets;

  /// Display name for each entry of [presets].
  final List<String> names;
  final int? activePresetIndex;

  final bool noneEnabled;
  final ValueChanged<int> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: swatchGap,
      runSpacing: swatchGap,
      children: [
        StyleColorSwatch.none(
          tooltip: names[0],
          isActive: activePresetIndex == 0,
          enabled: noneEnabled,
          onPressed: () => onPresetSelected(0),
        ),
        for (var i = 1; i < presets.length; i++)
          StyleColorSwatch(
            color: presets[i],
            tooltip: names[i],
            tooltipDetail: hexColor(presets[i]),
            isActive: activePresetIndex == i,
            onPressed: () => onPresetSelected(i),
          ),
      ],
    );
  }
}

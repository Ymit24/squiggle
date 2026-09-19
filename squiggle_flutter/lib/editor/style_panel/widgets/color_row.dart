import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/metrics.dart';

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.presets,
    required this.activePresetIndex,
    required this.noneEnabled,
    required this.onPresetSelected,
  });

  final List<Color> presets;
  final int? activePresetIndex;

  final bool noneEnabled;
  final ValueChanged<int> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: swatchGridWidth,
      child: Wrap(
        spacing: swatchGap,
        runSpacing: swatchGap,
        children: [
          StyleColorSwatch.none(
            isActive: activePresetIndex == 0,
            enabled: noneEnabled,
            onPressed: () => onPresetSelected(0),
          ),
          for (var i = 1; i < presets.length; i++)
            StyleColorSwatch(
              color: presets[i],
              isActive: activePresetIndex == i,
              onPressed: () => onPresetSelected(i),
            ),
        ],
      ),
    );
  }
}

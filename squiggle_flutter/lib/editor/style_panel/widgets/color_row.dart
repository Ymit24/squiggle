import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/metrics.dart';

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.presets,
    required this.activePresetIndex,
    required this.isNoneActive,
    required this.noneEnabled,
    required this.onPresetSelected,
    required this.onNoneSelected,
  });

  final List<Color> presets;
  final int? activePresetIndex;
  final bool isNoneActive;
  final bool noneEnabled;
  final ValueChanged<int> onPresetSelected;
  final VoidCallback onNoneSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: swatchGridWidth,
      child: Wrap(
        spacing: swatchGap,
        runSpacing: swatchGap,
        children: [
          StyleColorSwatch.none(
            isActive: isNoneActive,
            enabled: noneEnabled,
            onPressed: onNoneSelected,
          ),
          for (var i = 0; i < presets.length; i++)
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

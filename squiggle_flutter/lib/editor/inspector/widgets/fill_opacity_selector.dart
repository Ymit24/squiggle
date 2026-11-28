import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class FillOpacitySelector extends StatelessWidget {
  const FillOpacitySelector({
    super.key,
    required this.opacity,
    required this.isMixed,
    required this.onChanged,
  });

  final double opacity;
  final bool isMixed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final value = opacity.clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            padding: const EdgeInsets.symmetric(vertical: 8),
            activeColor: theme.colors.text,
            inactiveColor: theme.colors.surface1,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 40,
          child: Text(
            isMixed ? 'Mixed' : '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: theme.typography.inputText,
          ),
        ),
      ],
    );
  }
}

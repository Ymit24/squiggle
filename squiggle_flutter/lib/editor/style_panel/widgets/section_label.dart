import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/metrics.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: labelSpacing),
      child: Text(
        label,
        style: const TextStyle(
          color: SquiggleColors.subtext0,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

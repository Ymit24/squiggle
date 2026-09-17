import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

class EmptyDocumentPreviewGlyph extends StatelessWidget {
  const EmptyDocumentPreviewGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: SquiggleColors.surface0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SquiggleColors.surface1),
      ),
      child: const Icon(
        Icons.crop_square_rounded,
        size: 20,
        color: SquiggleColors.subtext0,
      ),
    );
  }
}

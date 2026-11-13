import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class EmptyDocumentPreviewGlyph extends StatelessWidget {
  const EmptyDocumentPreviewGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surface1),
      ),
      child: Icon(Icons.crop_square_rounded, size: 20, color: colors.subtext0),
    );
  }
}

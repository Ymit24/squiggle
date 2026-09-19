import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_icon_tile.dart';

class EmptyDocumentPreviewGlyph extends StatelessWidget {
  const EmptyDocumentPreviewGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return const SquiggleIconTile(icon: Icons.crop_square_rounded, radius: 12);
  }
}

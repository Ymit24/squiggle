import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LibraryMenuContent extends StatelessWidget {
  const LibraryMenuContent({super.key, required this.item});

  final LibraryMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    final color = item.danger ? colors.danger : colors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          if (item.icon case final icon?) ...[
            Icon(icon, size: 16, color: item.danger ? color : colors.subtext0),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              item.label,
              style: context.squiggleTheme.typography.body.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (item.checked) ...[
            const SizedBox(width: 12),
            Icon(Icons.check_rounded, size: 16, color: colors.accent),
          ],
        ],
      ),
    );
  }
}

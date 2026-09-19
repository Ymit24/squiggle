import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_content.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LibraryMenuButton extends StatelessWidget {
  const LibraryMenuButton({super.key, required this.item});

  final LibraryMenuItem item;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: item.onTap,
      requestFocusOnHover: false,
      style: MenuItemButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            context.squiggleTheme.radii.textEditPanel,
          ),
        ),
      ),
      child: LibraryMenuContent(item: item),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_content.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: LibraryMenuContent(item: item),
    );
  }
}

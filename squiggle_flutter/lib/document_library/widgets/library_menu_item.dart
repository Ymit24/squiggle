import 'package:flutter/material.dart';

class LibraryMenuItem {
  const LibraryMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
    this.checked = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;
  final bool checked;
}

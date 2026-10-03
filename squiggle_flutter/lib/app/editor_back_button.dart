import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Back control shown while editing a document.
class EditorBackButton extends StatelessWidget {
  const EditorBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SquiggleButton(
      onPressed: onPressed,
      icon: Icons.grid_view_rounded,
      label: 'Canvas library',
      variant: SquiggleButtonVariant.secondary,
      compact: true,
    );
  }
}

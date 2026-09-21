import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Back control shown while editing a document.
class EditorBackButton extends StatelessWidget {
  const EditorBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SquiggleButton.icon(
      icon: const Icon(Icons.grid_view_rounded),
      tooltip: 'Back to library',
      onPressed: onPressed,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_button.dart';

class NewDocumentButton extends StatelessWidget {
  const NewDocumentButton({
    super.key,
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      key: const ValueKey('library-new'),
      height: libraryHeaderControlHeight,
      child: SquiggleButton(
        onPressed: onTap,
        icon: Icons.add_rounded,
        label: compact ? null : 'New canvas',
        size: compact ? SquiggleButtonSize.compact : SquiggleButtonSize.regular,
        tooltip: compact ? 'New canvas' : null,
      ),
    );
    return button;
  }
}

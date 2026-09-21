import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

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
    return compact
        ? SquiggleButton.icon(
            key: const ValueKey('library-new'),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New canvas',
            variant: SquiggleButtonVariant.primary,
            onPressed: onTap,
          )
        : SquiggleButton(
            key: const ValueKey('library-new'),
            label: 'New canvas',
            leading: const Icon(Icons.add_rounded),
            variant: SquiggleButtonVariant.primary,
            onPressed: onTap,
          );
  }
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
    final theme = context.squiggleTheme;
    final button = SizedBox(
      key: const ValueKey('library-new'),
      height: libraryHeaderControlHeight,
      child: TextButton(
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? theme.colors.text.withValues(alpha: 0.9)
                : theme.colors.text,
          ),
          foregroundColor: WidgetStatePropertyAll(theme.colors.base),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, libraryHeaderControlHeight),
          ),
          maximumSize: const WidgetStatePropertyAll(
            Size(double.infinity, libraryHeaderControlHeight),
          ),
          fixedSize: compact
              ? const WidgetStatePropertyAll(
                  Size.square(libraryHeaderControlHeight),
                )
              : null,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(
            compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 11),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
        child: compact
            ? const Icon(Icons.add_rounded, size: 18)
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 17),
                  SizedBox(width: 5),
                  Text(
                    'New canvas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
    if (compact) {
      return Tooltip(message: 'New canvas', child: button);
    }
    return button;
  }
}

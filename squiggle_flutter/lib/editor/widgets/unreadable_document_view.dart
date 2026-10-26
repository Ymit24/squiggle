import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Shown instead of the editor when a document's stored data cannot be read.
///
/// The stored document is left untouched, and nothing is autosaved over it.
class UnreadableDocumentView extends StatelessWidget {
  const UnreadableDocumentView({super.key, required this.onBackToLibrary});

  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return ColoredBox(
      color: theme.colors.mantle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.report_gmailerrorred_rounded,
                  size: 32,
                  color: theme.colors.subtext0,
                ),
                const SizedBox(height: 16),
                Text(
                  "This canvas can't be opened",
                  style: theme.typography.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Its saved data could not be read. It has not been changed '
                  'or overwritten.',
                  textAlign: TextAlign.center,
                  style: theme.typography.inputText.copyWith(
                    color: theme.colors.subtext0,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 18),
                SquiggleButton(
                  onPressed: onBackToLibrary,
                  icon: Icons.arrow_back_rounded,
                  label: 'Back to library',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

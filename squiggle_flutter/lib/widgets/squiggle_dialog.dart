import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleDialog extends StatelessWidget {
  const SquiggleDialog({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.titleTrailing,
    required this.content,
    this.actions,
    this.contentWidth = 360,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;

  /// Shown at the end of the title row, such as a close button.
  final Widget? titleTrailing;
  final Widget content;

  /// Buttons along the bottom; null leaves the dialog without an action bar.
  final List<Widget>? actions;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    final tint = iconColor ?? colors.accent;

    return AlertDialog(
      backgroundColor: colors.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.surface1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.typography.inputText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          ?titleTrailing,
        ],
      ),
      content: SizedBox(width: contentWidth, child: content),
      actions: actions,
    );
  }
}

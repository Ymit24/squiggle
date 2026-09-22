import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleDialog extends StatelessWidget {
  const SquiggleDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.width,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;

    return AlertDialog(
      backgroundColor: colors.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.surface1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      title: title,
      content: width == null ? content : SizedBox(width: width, child: content),
      actions: actions,
    );
  }
}

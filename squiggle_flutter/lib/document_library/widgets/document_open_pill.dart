import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pill.dart';

class DocumentOpenPill extends StatelessWidget {
  const DocumentOpenPill({super.key, required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquigglePill(
      label: isCurrent ? 'Continue' : 'Open',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      backgroundColor: theme.colors.text,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      textStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      leading: Icon(
        isCurrent ? Icons.bolt_rounded : Icons.north_east_rounded,
        size: 14,
        color: Colors.black87,
      ),
    );
  }
}

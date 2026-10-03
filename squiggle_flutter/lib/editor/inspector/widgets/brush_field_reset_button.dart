import 'package:flutter/material.dart';

class BrushFieldResetButton extends StatelessWidget {
  const BrushFieldResetButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: IconButton(
      tooltip: 'Clear brush override',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.restart_alt, size: 16),
    ),
  );
}

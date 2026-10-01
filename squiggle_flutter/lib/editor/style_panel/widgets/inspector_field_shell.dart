import 'package:flutter/material.dart';

class InspectorFieldShell extends StatelessWidget {
  const InspectorFieldShell({
    super.key,
    required this.child,
    required this.label,
    this.onReset,
  });

  final Widget child;
  final String label;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          if (onReset != null)
            SizedBox(
              width: 20,
              height: 20,
              child: IconButton(
                tooltip: 'Clear brush override',
                onPressed: onReset,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.restart_alt, size: 16),
              ),
            ),
        ],
      ),
      child,
    ],
  );
}

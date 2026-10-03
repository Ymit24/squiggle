import 'package:flutter/material.dart';

class InspectorFieldShell extends StatelessWidget {
  const InspectorFieldShell({
    super.key,
    required this.child,
    required this.label,
    this.trailing,
  });

  final Widget child;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          ?trailing,
        ],
      ),
      child,
    ],
  );
}

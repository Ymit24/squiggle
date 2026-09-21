import 'package:flutter/material.dart';

class InspectorFieldShell extends StatelessWidget {
  const InspectorFieldShell({
    super.key,
    required this.child,
    required this.label,
  });

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label), child],
  );
}

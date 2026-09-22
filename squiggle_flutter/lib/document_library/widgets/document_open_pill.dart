import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_pill.dart';

class DocumentOpenPill extends StatelessWidget {
  const DocumentOpenPill({super.key, required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return SquigglePill.action(
      label: isCurrent ? 'Continue' : 'Open',
      icon: isCurrent ? Icons.bolt_rounded : Icons.north_east_rounded,
    );
  }
}

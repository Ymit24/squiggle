import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_pill.dart';

class CurrentDocumentBadge extends StatelessWidget {
  const CurrentDocumentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SquigglePill(label: 'Current');
  }
}

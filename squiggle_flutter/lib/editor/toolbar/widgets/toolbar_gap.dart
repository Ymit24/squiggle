import 'package:flutter/widgets.dart';

import 'toolbar_metrics.dart';

class ToolbarGap extends StatelessWidget {
  const ToolbarGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: toolbarGap);
  }
}

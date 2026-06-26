import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class Gap extends StatelessWidget {
  const Gap({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: context.squiggleTheme.spacing.toolbarGap);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/style_panel_content.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class StylePanel extends StatelessWidget {
  const StylePanel({super.key, required this.viewportHeight});

  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final spacing = context.squiggleTheme.spacing;
    final maxHeight =
        viewportHeight - spacing.overlayTop - spacing.overlaySide;

    return Positioned(
      top: spacing.overlayTop,
      bottom: spacing.overlaySide,
      left: spacing.overlaySide,
      child: Align(
        alignment: Alignment.topLeft,
        child: BlocBuilder<StylePanelBloc, StylePanelState>(
          builder: (context, state) => switch (state) {
            StylePanelHiddenState() => const SizedBox.shrink(),
            StylePanelShowingState() => StylePanelContent(
              state: state,
              maxHeight: maxHeight,
            ),
          },
        ),
      ),
    );
  }
}

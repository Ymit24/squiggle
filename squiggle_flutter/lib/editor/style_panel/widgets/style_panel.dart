import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/style_panel_content.dart';

class StylePanel extends StatelessWidget {
  const StylePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topLeft,
        child: BlocBuilder<StylePanelBloc, StylePanelState>(
          builder: (context, state) => switch (state) {
            StylePanelHiddenState() => const SizedBox.shrink(),
            StylePanelShowingState() => StylePanelContent(
              state: state,
              maxHeight: constraints.maxHeight,
            ),
          },
        ),
      ),
    );
  }
}

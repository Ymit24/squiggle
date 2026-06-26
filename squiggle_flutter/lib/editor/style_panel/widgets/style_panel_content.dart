import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_row.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/section_label.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/font_size_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/stroke_width_selector.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class StylePanelContent extends StatelessWidget {
  const StylePanelContent({super.key, required this.state});

  final StylePanelShowingState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final bloc = context.read<StylePanelBloc>();

    return DecoratedBox(
      decoration: theme.decorations.floatingPanel(),
      child: Padding(
        padding: EdgeInsets.all(spacing.panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionLabel('Stroke'),
            ColorRow(
              presets: stylePresets.map((preset) => preset.strokeColor).toList(),
              activePresetIndex: state.strokeMixed
                  ? null
                  : state.activeStrokePresetIndex,
              isNoneActive: state.isStrokeNone,
              noneEnabled: state.canClearStroke,
              onPresetSelected: (index) =>
                  bloc.add(SetStrokePresetEvent(index)),
              onNoneSelected: () => bloc.add(const ClearStrokeEvent()),
            ),
            SizedBox(height: spacing.panelSectionSpacing),
            SectionLabel('Fill'),
            ColorRow(
              presets: stylePresets.map((preset) => preset.fillColor).toList(),
              activePresetIndex: state.fillMixed
                  ? null
                  : state.activeFillPresetIndex,
              isNoneActive: state.isFillNone,
              noneEnabled: state.canClearFill,
              onPresetSelected: (index) => bloc.add(SetFillPresetEvent(index)),
              onNoneSelected: () => bloc.add(const ClearFillEvent()),
            ),
            SizedBox(height: spacing.panelSectionSpacing),
            SectionLabel('Width'),
            StrokeWidthSelector(
              activePreset: state.activeStrokeWidth,
              isMixed: state.strokeWidthMixed,
              onPresetSelected: (preset) =>
                  bloc.add(SetStrokeWidthEvent(preset)),
            ),
            if (state.showFontSize) ...[
              SizedBox(height: spacing.panelSectionSpacing),
              SectionLabel('Font size'),
              FontSizeSelector(
                activePreset: state.activeFontSize,
                isMixed: state.fontSizeMixed,
                onPresetSelected: (preset) =>
                    bloc.add(SetFontSizeEvent(preset)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

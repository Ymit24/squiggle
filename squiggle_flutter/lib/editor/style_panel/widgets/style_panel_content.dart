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
import 'package:squiggle_flutter/editor/style_panel/widgets/node_layout_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/line_end_cap_selector.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/text_alignment_selector.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class StylePanelContent extends StatelessWidget {
  const StylePanelContent({
    super.key,
    required this.state,
    required this.maxHeight,
  });

  final StylePanelShowingState state;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final bloc = context.read<StylePanelBloc>();

    return DecoratedBox(
      decoration: theme.decorations.floatingPanel(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.panelPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.showStyleControls) ...[
                  SectionLabel('Stroke'),
                  ColorRow(
                    presets: stylePresets
                        .map((preset) => preset.strokeColor)
                        .toList(),
                    activePresetIndex: state.strokeMixed
                        ? null
                        : state.activeStrokePresetIndex,

                    noneEnabled: state.canClearStroke,
                    onPresetSelected: (index) => index == -1
                        ? bloc.add(const ClearStrokeEvent())
                        : bloc.add(SetStrokePresetEvent(index)),
                  ),
                  SizedBox(height: spacing.panelSectionSpacing),
                  if (state.showFillControls) ...[
                    SectionLabel('Fill'),
                    ColorRow(
                      presets: stylePresets
                          .map((preset) => preset.fillColor)
                          .toList(),
                      activePresetIndex: state.fillMixed
                          ? null
                          : state.activeFillPresetIndex,

                      noneEnabled: state.canClearFill,
                      onPresetSelected: (index) => index == -1
                          ? bloc.add(const ClearFillEvent())
                          : bloc.add(SetFillPresetEvent(index)),
                    ),
                    SizedBox(height: spacing.panelSectionSpacing),
                  ],
                  SectionLabel('Width'),
                  StrokeWidthSelector(
                    activePreset: state.activeStrokeWidth,
                    isMixed: state.strokeWidthMixed,
                    onPresetSelected: (preset) =>
                        bloc.add(SetStrokeWidthEvent(preset)),
                  ),
                  if (state.showEndCaps) ...[
                    SizedBox(height: spacing.panelSectionSpacing),
                    SectionLabel('Start cap'),
                    LineEndCapSelector(
                      activeEndCap: state.activeStartEndCap,
                      isMixed: state.startEndCapMixed,
                      isStart: true,
                      onEndCapSelected: (endCap) =>
                          bloc.add(SetStartEndCapEvent(endCap)),
                    ),
                    SizedBox(height: spacing.panelSectionSpacing),
                    SectionLabel('End cap'),
                    LineEndCapSelector(
                      activeEndCap: state.activeEndEndCap,
                      isMixed: state.endEndCapMixed,
                      isStart: false,
                      onEndCapSelected: (endCap) =>
                          bloc.add(SetEndEndCapEvent(endCap)),
                    ),
                  ],
                ],
                if (state.selectedNodeIds.length >= 2) ...[
                  if (state.showStyleControls)
                    SizedBox(height: spacing.panelSectionSpacing),
                  SectionLabel('Align'),
                  NodeAlignSelector(
                    onAlign: (alignment) =>
                        bloc.add(AlignNodesEvent(alignment)),
                  ),
                ],
                if (state.selectedNodeIds.length >= 3) ...[
                  SizedBox(height: spacing.panelSectionSpacing),
                  SectionLabel('Distribute'),
                  NodeDistributeSelector(
                    onDistribute: (distribution) =>
                        bloc.add(DistributeNodesEvent(distribution)),
                  ),
                ],
                if (state.showFontSize) ...[
                  SizedBox(height: spacing.panelSectionSpacing),
                  SectionLabel('Font size'),
                  FontSizeSelector(
                    activePreset: state.activeFontSize,
                    isMixed: state.fontSizeMixed,
                    onPresetSelected: (preset) =>
                        bloc.add(SetFontSizeEvent(preset)),
                  ),
                  SizedBox(height: spacing.panelSectionSpacing),
                  SectionLabel('Align horizontal'),
                  TextHorizontalAlignmentSelector(
                    activeAlignment: state.activeHorizontalAlignment,
                    isMixed: state.horizontalAlignmentMixed,
                    onAlignmentSelected: (alignment) =>
                        bloc.add(SetTextHorizontalAlignmentEvent(alignment)),
                  ),
                  SizedBox(height: spacing.panelSectionSpacing),
                  SectionLabel('Align vertical'),
                  TextVerticalAlignmentSelector(
                    activeAlignment: state.activeVerticalAlignment,
                    isMixed: state.verticalAlignmentMixed,
                    onAlignmentSelected: (alignment) =>
                        bloc.add(SetTextVerticalAlignmentEvent(alignment)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

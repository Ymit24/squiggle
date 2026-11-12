import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/library_search_field.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/color_row.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/font_size_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/line_end_cap_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/stroke_width_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/text_horizontal_alignment_selector.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/text_vertical_alignment_selector.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: SquiggleThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  test('hexColor formats RGB without alpha', () {
    expect(hexColor(const Color(0xFFC4597A)), '#C4597A');
    expect(hexColor(const Color(0x00000000)), '#000000');
    expect(hexColor(const Color(0xFF0A0B0C)), '#0A0B0C');
  });

  testWidgets('colour swatches show the preset name and hex', (tester) async {
    await _pump(
      tester,
      SizedBox(
        width: 400,
        child: ColorRow(
          presets: stylePresets.map((p) => p.strokeColor).toList(),
          names: stylePresets.map((p) => p.name).toList(),
          activePresetIndex: 1,
          noneEnabled: true,
          onPresetSelected: (_) {},
        ),
      ),
    );
    expect(find.byTooltip('None'), findsOneWidget);
    expect(find.byTooltip('Rose  #C4597A'), findsOneWidget);
    expect(find.byTooltip('Charcoal  #2E3244'), findsOneWidget);
    expect(find.byType(Tooltip), findsNWidgets(stylePresets.length));
    expect(
      stylePresets.map((p) => p.name).toSet(),
      hasLength(stylePresets.length),
      reason: 'preset names must be distinct',
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Rose'))),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
  });

  testWidgets('icon-only inspector swatches have tooltips', (tester) async {
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextHorizontalAlignmentSelector(
            activeAlignment: TextHorizontalAlignment.left,
            isMixed: false,
            onAlignmentSelected: (_) {},
          ),
          TextVerticalAlignmentSelector(
            activeAlignment: TextVerticalAlignment.top,
            isMixed: false,
            onAlignmentSelected: (_) {},
          ),
          LineEndCapSelector(
            activeEndCap: LineEndCap.rounded,
            isMixed: false,
            isStart: true,
            onEndCapSelected: (_) {},
          ),
          LineEndCapSelector(
            activeEndCap: LineEndCap.arrow,
            isMixed: false,
            isStart: false,
            onEndCapSelected: (_) {},
          ),
          StrokeWidthSelector(
            activePreset: StrokeWidthPreset.medium,
            isMixed: false,
            onPresetSelected: (_) {},
          ),
          FontSizeSelector(
            activePreset: FontSizePreset.medium,
            isMixed: false,
            onPresetSelected: (_) {},
          ),
        ],
      ),
    );
    for (final tooltip in [
      'Align left',
      'Align center',
      'Align right',
      'Align top',
      'Align middle',
      'Align bottom',
      'Round start',
      'Arrow start',
      'Round end',
      'Arrow end',
      'Thin',
      'Thick',
      'Small',
      'Large',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
    // Stroke width and font size both have a 'Medium' option.
    expect(find.byTooltip('Medium'), findsNWidgets(2));
  });

  testWidgets('search clear button has a tooltip', (tester) async {
    final controller = TextEditingController(text: 'abc');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      SizedBox(
        width: 250,
        child: LibrarySearchField(
          controller: controller,
          focusNode: focusNode,
          onTapOutside: () {},
          query: 'abc',
          onChanged: (_) {},
          onClear: () {},
        ),
      ),
    );
    expect(find.byTooltip('Clear search'), findsOneWidget);
  });
}

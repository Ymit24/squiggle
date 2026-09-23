import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

void main() {
  final colors = SquiggleTheme.dark.colors;

  Future<ButtonStyle> buttonStyle(
    WidgetTester tester, {
    SquiggleButtonVariant variant = SquiggleButtonVariant.primary,
    bool enabled = true,
    bool compact = false,
    SquiggleTheme? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: [theme ?? SquiggleTheme.dark],
        ),
        home: Scaffold(
          body: Center(
            child: SquiggleButton(
              onPressed: enabled ? () {} : null,
              label: 'Create',
              icon: Icons.add,
              variant: variant,
              compact: compact,
            ),
          ),
        ),
      ),
    );
    return tester.widget<FilledButton>(find.byType(FilledButton)).style!;
  }

  testWidgets('every variant owns its interaction colors', (tester) async {
    final expected = <SquiggleButtonVariant, (Color, Color, Color)>{
      SquiggleButtonVariant.primary: (
        colors.text,
        colors.accent,
        colors.subtext0,
      ),
      SquiggleButtonVariant.secondary: (
        colors.surface0,
        colors.surface1,
        colors.mantle,
      ),
      SquiggleButtonVariant.danger: (
        colors.onDanger,
        colors.danger,
        Color.lerp(colors.onDanger, colors.base, 0.2)!,
      ),
      SquiggleButtonVariant.ghost: (
        Colors.transparent,
        colors.surface0,
        colors.surface1,
      ),
    };

    for (final entry in expected.entries) {
      final style = await buttonStyle(tester, variant: entry.key);
      Color? background(Set<WidgetState> states) =>
          style.backgroundColor!.resolve(states);

      expect(background({}), entry.value.$1, reason: '${entry.key} idle');
      expect(
        background({WidgetState.hovered}),
        entry.value.$2,
        reason: '${entry.key} hovered',
      );
      expect(
        background({WidgetState.focused}),
        entry.value.$2,
        reason: '${entry.key} focused',
      );
      expect(
        background({WidgetState.pressed}),
        entry.value.$3,
        reason: '${entry.key} pressed',
      );
      expect(
        style.overlayColor!.resolve({WidgetState.hovered}),
        Colors.transparent,
      );
      expect(
        style.overlayColor!.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(style.side!.resolve({WidgetState.focused})!.color, colors.accent);

      final disabled = await buttonStyle(
        tester,
        variant: entry.key,
        enabled: false,
      );
      expect(
        disabled.backgroundColor!.resolve({WidgetState.disabled}),
        entry.key == SquiggleButtonVariant.ghost
            ? Colors.transparent
            : colors.surface0,
      );
      expect(
        disabled.foregroundColor!.resolve({WidgetState.disabled}),
        colors.subtext0.withValues(alpha: 0.5),
      );
    }
  });

  testWidgets('default is primary and metrics follow theme tokens', (
    tester,
  ) async {
    final theme = SquiggleTheme.dark.copyWith(
      spacing: SquiggleTheme.dark.spacing.copyWith(
        buttonHeight: 44,
        buttonHorizontalPadding: 19,
        buttonIconSize: 22,
        buttonIconGap: 9,
      ),
      radii: SquiggleTheme.dark.radii.copyWith(button: 10),
    );
    final style = await buttonStyle(tester, theme: theme);

    expect(style.backgroundColor!.resolve({}), colors.text);
    expect(style.minimumSize!.resolve({}), const Size(0, 44));
    expect(
      style.padding!.resolve({}),
      const EdgeInsets.symmetric(horizontal: 19),
    );
    expect(
      (style.shape!.resolve({}) as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(10),
    );
    expect(
      style.textStyle!.resolve({})!.fontSize,
      theme.typography.actionButtonLabel.fontSize,
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 22);
    expect(tester.widget<SizedBox>(find.byType(SizedBox).last).width, 9);

    final compactStyle = await buttonStyle(tester, theme: theme, compact: true);
    expect(compactStyle.fixedSize!.resolve({}), const Size.square(44));
    expect(compactStyle.padding!.resolve({}), EdgeInsets.zero);
    expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 22);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';

Future<void> _pumpMenu(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: LibraryMenuAnchor(
            menuWidth: 216,
            menuItems: () => [
              LibraryMenuItem(
                label: 'Last edited',
                icon: Icons.schedule_rounded,
                checked: true,
                onTap: () {},
              ),
              LibraryMenuItem(
                label: 'Oldest first',
                icon: Icons.history_rounded,
                onTap: () {},
              ),
              LibraryMenuItem(
                label: 'Name A–Z',
                icon: Icons.sort_by_alpha_rounded,
                onTap: () {},
              ),
            ],
            buttonBuilder: (context, open, toggle) =>
                TextButton(onPressed: toggle, child: const Text('Sort')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('anchored menu shrink-wraps instead of filling the window', (
    tester,
  ) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Sort'));
    await tester.pump();

    expect(find.byType(MenuItemButton), findsNWidgets(3));
    expect(
      tester.getSize(find.byType(MenuItemButton).first).height,
      lessThan(60),
    );
    expect(find.text('Last edited'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Name A–Z'), findsOneWidget);

    final labelBounds = tester.getRect(find.text('Last edited'));
    final checkBounds = tester.getRect(find.byIcon(Icons.check_rounded));
    expect(checkBounds.left - labelBounds.right, greaterThanOrEqualTo(12));
  });

  testWidgets('tapping the button again closes the menu', (tester) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Sort'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(3));

    await tester.tap(find.text('Sort'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNothing);
  });

  testWidgets('selecting an item closes the menu and fires onTap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LibraryMenuAnchor(
              menuWidth: 216,
              menuItems: () => [
                LibraryMenuItem(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                  onTap: () => tapped = true,
                ),
              ],
              buttonBuilder: (context, open, toggle) =>
                  TextButton(onPressed: toggle, child: const Text('Menu')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Menu'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(tapped, isTrue);
  });

  testWidgets('menu labels use the app text style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: LibraryMenuAnchor(
              menuWidth: 216,
              menuItems: () => [
                LibraryMenuItem(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                  onTap: () {},
                ),
              ],
              buttonBuilder: (context, open, toggle) =>
                  TextButton(onPressed: toggle, child: const Text('Menu')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Menu'));
    await tester.pump();

    final label = find.text('Delete');
    final ambient = DefaultTextStyle.of(tester.element(label)).style;
    final paragraph = tester.renderObject<RenderParagraph>(label);
    expect(ambient.decoration, TextDecoration.none);
    expect(paragraph.text.style?.decoration, TextDecoration.none);
    expect(paragraph.text.style?.fontFamily, isNot('monospace'));
  });
}

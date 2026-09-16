import 'package:flutter/material.dart';
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
            buttonBuilder: (context, open, toggle) => TextButton(
              onPressed: toggle,
              child: const Text('Sort'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('anchored menu shrink-wraps instead of filling the window',
      (tester) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Sort'));
    await tester.pump();

    final panelFinder = find.byType(LibraryMenuPanel);
    expect(panelFinder, findsOneWidget);

    final panelSize = tester.getSize(panelFinder);
    // Three ~40px rows plus padding: compact. Full-window height means the
    // overlay passed tight constraints straight through (regression).
    expect(panelSize.height, lessThan(300));
    expect(panelSize.width, 216);

    // All rows actually render their labels.
    expect(find.text('Last edited'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Name A–Z'), findsOneWidget);
  });

  testWidgets('tapping the button again closes the menu', (tester) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Sort'));
    await tester.pump();
    expect(find.byType(LibraryMenuPanel), findsOneWidget);

    await tester.tap(find.text('Sort'));
    await tester.pump();
    expect(find.byType(LibraryMenuPanel), findsNothing);
  });

  testWidgets('selecting an item closes the menu and fires onTap',
      (tester) async {
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
              buttonBuilder: (context, open, toggle) => TextButton(
                onPressed: toggle,
                child: const Text('Menu'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Menu'));
    await tester.pump();
    expect(find.byType(LibraryMenuPanel), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.byType(LibraryMenuPanel), findsNothing);
    expect(tapped, isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card_menu_button.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_anchor.dart';
import 'package:squiggle_flutter/document_library/widgets/library_sort_button.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  testWidgets('context actions dismiss before opening a rename dialog', (
    tester,
  ) async {
    var renames = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLibraryContextMenu(
                context: context,
                position: const Offset(790, 590),
                items: [
                  LibraryMenuItem(
                    label: 'Rename',
                    onTap: () {
                      renames++;
                      showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const AlertDialog(content: Text('Rename document')),
                      );
                    },
                  ),
                ],
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(renames, 1);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Rename document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document menu survives parent rebuilds and reports dismissal', (
    tester,
  ) async {
    var open = false;
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Text(open ? 'Menu open' : 'Menu closed'),
                DocumentCardMenuButton(
                  canDelete: true,
                  onRename: () {},
                  onDelete: () => deletes++,
                  onOpenChanged: (value) => setState(() => open = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Document actions'));
    await tester.pumpAndSettle();
    expect(find.text('Menu open'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(find.text('Menu closed'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await tester.tap(find.byTooltip('Document actions'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(open, isFalse);
    expect(deletes, 1);
  });

  testWidgets(
    'sort menu supports keyboard selection and closes after changing',
    (tester) async {
      var sort = DocumentSortMode.recent;
      await tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: LibrarySortButton(
                sort: sort,
                onChanged: (value) => setState(() => sort = value),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('library-sort')));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Last edited'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(sort, DocumentSortMode.oldest);
      expect(find.text('Oldest'), findsOneWidget);
      expect(find.text('Oldest first'), findsNothing);
    },
  );
}

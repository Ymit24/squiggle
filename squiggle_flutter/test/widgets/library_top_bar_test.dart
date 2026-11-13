import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/library_header.dart';
import 'package:squiggle_flutter/document_library/widgets/library_sort_button.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  // From the 640px minimum window, across the compact breakpoint (760px), to
  // where the search field reaches full width.
  for (final width in <double>[640, 759, 760, 800, 900, 1200]) {
    testWidgets('the library top bar fits a ${width}px window', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: Scaffold(
            body: LibraryHeader(
              searchController: searchController,
              searchFocus: searchFocus,
              onSearchTapOutside: () {},
              query: '',
              sort: DocumentSortMode.values.first,
              onQueryChanged: (_) {},
              onClearQuery: () {},
              onSortChanged: (_) {},
              onCreateNamed: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}

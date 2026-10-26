import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/widgets/unreadable_document_view.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  testWidgets('offers a way back to the library', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: UnreadableDocumentView(onBackToLibrary: () => backs++),
        ),
      ),
    );

    expect(find.text("This canvas can't be opened"), findsOneWidget);
    await tester.tap(find.text('Back to library'));

    expect(backs, 1);
  });
}

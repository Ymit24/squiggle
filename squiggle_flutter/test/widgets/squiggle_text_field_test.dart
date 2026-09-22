import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/library_search_field.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

void main() {
  testWidgets('name dialog keeps its field styling and Enter submission', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                submitted = await showDocumentNameDialog(
                  context,
                  title: 'New canvas',
                  confirmLabel: 'Create',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(SquiggleTextField), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);
    expect(field.selectAllOnFocus, isTrue);
    expect(
      field.decoration!.contentPadding,
      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    );
    expect(
      (field.decoration!.focusedBorder! as OutlineInputBorder).borderSide,
      BorderSide(
        color: SquiggleTheme.dark.colors.accent.withValues(alpha: 0.7),
        width: 1.4,
      ),
    );

    await tester.enterText(find.byType(TextField), 'My canvas');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(submitted, 'My canvas');
  });

  testWidgets('library search keeps its icons, sizing, and text callback', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? changed;
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: LibrarySearchField(
            controller: controller,
            focusNode: focusNode,
            onTapOutside: () {},
            query: '',
            onChanged: (value) => changed = value,
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.byType(SquiggleTextField), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode, same(focusNode));
    expect(field.decoration!.contentPadding, EdgeInsets.zero);
    expect(field.decoration!.prefixIconConstraints!.minWidth, 36);
    expect(field.decoration!.suffixIconConstraints!.minWidth, 42);
    expect(
      (field.decoration!.focusedBorder! as OutlineInputBorder).borderSide,
      BorderSide(
        color: SquiggleTheme.dark.colors.accent.withValues(alpha: 0.6),
      ),
    );

    await tester.enterText(find.byType(TextField), 'notes');
    expect(changed, 'notes');
    controller.dispose();
    focusNode.dispose();
  });
}

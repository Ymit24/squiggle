import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/delete_document_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';

void main() {
  void expectDialogShell(WidgetTester tester, double width) {
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    final colors = SquiggleTheme.dark.colors;

    expect(find.byType(SquiggleDialog), findsOneWidget);
    expect(dialog.backgroundColor, colors.base);
    expect(
      dialog.shape,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.surface1),
      ),
    );
    expect(dialog.titlePadding, const EdgeInsets.fromLTRB(22, 20, 22, 0));
    expect(dialog.contentPadding, const EdgeInsets.fromLTRB(22, 12, 22, 0));
    expect(dialog.actionsPadding, const EdgeInsets.fromLTRB(16, 16, 16, 14));
    expect(dialog.content, isA<SizedBox>());
    expect((dialog.content! as SizedBox).width, width);
  }

  testWidgets('delete dialog keeps its shell and confirmation behavior', (
    tester,
  ) async {
    bool? confirmed;
    final document = DocumentInfo(
      id: 'canvas-1',
      name: 'Sketch',
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) =>
                      DeleteDocumentDialog(document: document),
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
    expectDialogShell(tester, 340);
    expect(find.textContaining('Sketch'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('name dialog keeps its shell and submits its entered name', (
    tester,
  ) async {
    String? name;

    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                name = await showDocumentNameDialog(
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
    expectDialogShell(tester, 360);
    expect(find.text('New canvas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sketch');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(name, 'Sketch');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_panel.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    required FocusNode focusNode,
    required void Function(String text) onAccept,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextEditPanel(
            textFocusNode: focusNode,
            initialContents: 'hello',
            maxHeight: 200,
            onCancel: () {},
            onAccept: onAccept,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
  }

  testWidgets('Cmd+Enter accepts text like the Accept button', (tester) async {
    final focusNode = FocusNode();
    String? acceptedText;

    await pumpPanel(
      tester,
      focusNode: focusNode,
      onAccept: (text) => acceptedText = text,
    );

    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.metaLeft,
      platform: 'macos',
    );
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.enter,
      platform: 'macos',
    );
    await tester.pump();

    expect(acceptedText, 'hello');
  });

  testWidgets('Ctrl+Enter accepts text like the Accept button', (tester) async {
    final focusNode = FocusNode();
    String? acceptedText;

    await pumpPanel(
      tester,
      focusNode: focusNode,
      onAccept: (text) => acceptedText = text,
    );

    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.enter,
      platform: 'windows',
    );
    await tester.pump();

    expect(acceptedText, 'hello');
  });

  testWidgets('does not overflow when constrained to minimum panel width', (
    tester,
  ) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: textEditPanelMinWidth,
            child: TextEditPanel(
              textFocusNode: focusNode,
              initialContents: 'hello',
              maxHeight: 200,
              onCancel: () {},
              onAccept: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
  });
}

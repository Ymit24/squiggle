import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';

// Overlay entries live above the page's Scaffold, so without a Material
// ancestor menu labels inherit Flutter's debug fallback style (monospace
// with a yellow double underline). This guards against regressing that.
void main() {
  testWidgets('overlay menu labels do not inherit the fallback text style',
      (tester) async {
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

    final labelElement = tester.element(find.text('Delete'));
    final ambient = DefaultTextStyle.of(labelElement).style;
    expect(ambient.decoration, TextDecoration.none);

    final paragraph =
        tester.renderObject<RenderParagraph>(find.text('Delete'));
    expect(paragraph.text.style?.decoration, TextDecoration.none);
    expect(paragraph.text.style?.fontFamily, isNot('monospace'));
  });
}

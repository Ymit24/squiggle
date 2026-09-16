import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/style_panel.dart';
import 'package:squiggle_flutter/models/document.dart';

void main() {
  testWidgets('can be laid out in the editor overlay column', (tester) async {
    final editorContext = EditorContext(document: Document());
    final bloc = StylePanelBloc(context: editorContext);
    addTearDown(bloc.close);
    addTearDown(editorContext.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: const Column(
              children: [
                SizedBox(height: 40),
                Expanded(child: StylePanel()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

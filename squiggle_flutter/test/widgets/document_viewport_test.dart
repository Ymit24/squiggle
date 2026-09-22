import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/widgets/document_canvas.dart';
import 'package:squiggle_flutter/widgets/document_viewport.dart';

void main() {
  testWidgets('preserves the canvas across parent rebuilds', (tester) async {
    final editorContext = EditorContext(document: Document());
    final imageRepository = ImageRepository();
    final textEditBloc = TextEditBloc(context: editorContext);
    addTearDown(editorContext.dispose);
    addTearDown(imageRepository.dispose);
    addTearDown(textEditBloc.close);

    Widget buildViewport() {
      return BlocProvider.value(
        value: textEditBloc,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DocumentViewport(
            editorContext: editorContext,
            imageRepository: imageRepository,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildViewport());
    final originalCanvas = tester.renderObject(find.byType(DocumentCanvas));

    await tester.pumpWidget(buildViewport());

    expect(tester.renderObject(find.byType(DocumentCanvas)), originalCanvas);
  });
}

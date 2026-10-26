// Web-friendly harness that opens the real Editor on a seeded document, so the
// inline text editor can be tried without the native-only app shell:
//   flutter run -d web-server -t tool/inline_text_demo.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  final context = EditorContext(
    document: Document.fromFeatures([
      Feature(
        origin: const Offset(160, 140),
        size: const Size(260, 150),
        kind: FeatureKindRectangle(label: 'Rectangle label'),
      ),
      Feature(
        origin: const Offset(520, 140),
        size: const Size(220, 160),
        kind: FeatureKindCircle(label: 'Circle'),
      ),
      Feature(
        origin: const Offset(160, 380),
        size: const Size(300, 70),
        kind: FeatureKindText(
          'Double-click me to edit this text in place',
          fontSize: 28,
        ),
      ),
      Feature(
        origin: const Offset(560, 380),
        size: const Size(220, 70),
        kind: FeatureKindText(
          'Centered\nmulti-line',
          fontSize: 24,
          horizontalAlignment: TextHorizontalAlignment.center,
        ),
      ),
    ]),
  );

  runApp(
    ChangeNotifierProvider.value(
      value: context,
      child: RepositoryProvider(
        create: (_) => ImageRepository(),
        child: MaterialApp(
          theme: SquiggleThemeData.dark(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Editor(editorContext: context, onBackToLibrary: () {}),
          ),
        ),
      ),
    ),
  );
}

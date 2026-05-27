import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

import 'models/document.dart';
import 'models/feature.dart';
import 'widgets/document_viewport.dart';

void main() {
  runApp(const SquiggleApp());
}

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squiggle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF89B4FA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SquiggleHomePage(),
    );
  }
}

class SquiggleHomePage extends StatelessWidget {
  const SquiggleHomePage({super.key});

  static final _document = Document.fromFeatures([
    Feature.newRectangle(const Offset(64, 64), const Size(160, 96)),
    Feature.newCircle(const Offset(320, 128), const Size(120, 120)),
    Feature.newText(
      const Offset(64, 256),
      const Size(500, 48),
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac facilisis nunc. Proin maximus orci in leo luctus, sed cursus ante efficitur. Integer porttitor augue purus. In ac diam at purus condimentum posuere at a purus. Maecenas feugiat, mauris eu sagittis imperdiet, turpis enim cursus neque, eu pharetra elit sem sit amet massa. Phasellus luctus maximus lectus at tincidunt. Nullam in bibendum justo. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; ',
    ),
    Feature.newText(
      const Offset(500, 50),
      const Size(300, 48),
      'Hello world! This is some real text... What is something else to try?',
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepositoryProvider(
        create: (context) => SelectionRepository(),
        child: Editor(document: _document),
      ),
    );
  }
}

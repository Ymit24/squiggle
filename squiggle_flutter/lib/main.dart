import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';

import 'models/feature.dart';

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

  static final _documentRepository = DocumentRepository.fromFeatures([
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
        child: RepositoryProvider(
          create: (context) => ToolRepository(),
          dispose: (repository) => repository.dispose(),
          child: RepositoryProvider(
            create: (context) => _documentRepository,
            dispose: (repository) => repository.dispose(),
            child: BlocProvider(
              create: (context) => ToolbarBloc(
                toolRepository: context.read<ToolRepository>(),
                selectionRepository: context.read<SelectionRepository>(),
              ),
              child: Editor(documentRepository: _documentRepository),
            ),
          ),
        ),
      ),
    );
  }
}

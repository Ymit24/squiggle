import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

import 'models/feature.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imageRepository = ImageRepository();
  await imageRepository.initialize();
  runApp(SquiggleApp(imageRepository: imageRepository));
}

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({super.key, required this.imageRepository});

  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squiggle',
      theme: SquiggleThemeData.dark(),
      home: SquiggleHomePage(imageRepository: imageRepository),
    );
  }
}

class SquiggleHomePage extends StatelessWidget {
  SquiggleHomePage({super.key, required ImageRepository imageRepository})
    : _imageRepository = imageRepository;

  final ImageRepository _imageRepository;
  final _viewportRepository = ViewportRepository();

  static final _documentRepository = DocumentRepository(
    document: Document.fromFeatures([
    Feature(
      origin: const Offset(64, 64),
      size: const Size(160, 96),
      kind: const FeatureKindRectangle(),
    ),
    Feature(
      origin: const Offset(320, 128),
      size: const Size(120, 120),
      kind: const FeatureKindCircle(),
    ),
    Feature(
      origin: const Offset(64, 256),
      size: const Size(500, 48),
      kind: const FeatureKindText(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac facilisis nunc. Proin maximus orci in leo luctus, sed cursus ante efficitur. Integer porttitor augue purus. In ac diam at purus condimentum posuere at a purus. Maecenas feugiat, mauris eu sagittis imperdiet, turpis enim cursus neque, eu pharetra elit sem sit amet massa. Phasellus luctus maximus lectus at tincidunt. Nullam in bibendum justo. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; ',
        fillColor: defaultNewTextFillColor,
        strokeColor: defaultNewTextStrokeColor,
      ),
    ),
    Feature(
      origin: const Offset(500, 50),
      size: const Size(300, 48),
      kind: const FeatureKindText(
        'Hello world! This is some real text... What is something else to try?',
        fillColor: defaultNewTextFillColor,
        strokeColor: defaultNewTextStrokeColor,
      ),
    ),
    Feature(
      origin: const Offset(600, 200),
      size: const Size(300, 80),
      kind: const FeatureKindPolyline(
        [Offset.zero, Offset(300, 80)],
        strokeColor: defaultFeatureStrokeColor,
        fillColor: SquiggleColors.accent,
      ),
    ),
    Feature(
      origin: const Offset(600, 400),
      size: const Size(250, 120),
      kind: const FeatureKindPolyline(
        [
          Offset.zero,
          Offset(80, 40),
          Offset(160, 0),
          Offset(200, 80),
          Offset(250, 40),
          Offset(250, 120),
        ],
        strokeColor: defaultFeatureStrokeColor,
        fillColor: Color(0xFFE8B8C8),
      ),
    ),
    ]),
  );

  static final _textEditRepository = TextEditRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepositoryProvider(
        create: (context) => SelectionRepository(),
        child: RepositoryProvider(
          create: (context) => _textEditRepository,
          dispose: (repository) => repository.dispose(),
          child: RepositoryProvider(
            create: (context) => ToolRepository(),
            dispose: (repository) => repository.dispose(),
            child: RepositoryProvider(
              create: (context) => _imageRepository,
              dispose: (repository) => repository.dispose(),
              child: RepositoryProvider(
                create: (context) => _viewportRepository,
                child: RepositoryProvider(
                  create: (context) => _documentRepository,
                  dispose: (repository) => repository.dispose(),
                  child: BlocProvider(
                    create: (context) => ToolbarBloc(
                      toolRepository: context.read<ToolRepository>(),
                      selectionRepository: context.read<SelectionRepository>(),
                      documentRepository: context.read<DocumentRepository>(),
                    )..add(const RequestWatchToolbarStateEvent()),
                    child: Editor(documentRepository: _documentRepository),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

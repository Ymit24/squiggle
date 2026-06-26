import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/editor.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imageRepository = ImageRepository();
  await imageRepository.initialize();

  final documentStorage = DocumentStorage(imageRepository: imageRepository);
  await documentStorage.initialize();
  final document = await documentStorage.load() ?? Document();
  final documentRepository = DocumentRepository(document: document);
  documentStorage.attachAutosave(documentRepository);

  runApp(
    SquiggleApp(
      imageRepository: imageRepository,
      documentRepository: documentRepository,
      documentStorage: documentStorage,
    ),
  );
}

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.imageRepository,
    required this.documentRepository,
    required this.documentStorage,
  });

  final ImageRepository imageRepository;
  final DocumentRepository documentRepository;
  final DocumentStorage documentStorage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squiggle',
      theme: SquiggleThemeData.dark(),
      home: SquiggleHomePage(
        imageRepository: imageRepository,
        documentRepository: documentRepository,
        documentStorage: documentStorage,
      ),
    );
  }
}

class SquiggleHomePage extends StatelessWidget {
  SquiggleHomePage({
    super.key,
    required ImageRepository imageRepository,
    required this.documentRepository,
    required this.documentStorage,
  }) : _imageRepository = imageRepository;

  final ImageRepository _imageRepository;
  final DocumentRepository documentRepository;
  final DocumentStorage documentStorage;
  final _viewportRepository = ViewportRepository();
  final _textEditRepository = TextEditRepository();

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
                  create: (context) => documentRepository,
                  dispose: (repository) => repository.dispose(),
                  child: RepositoryProvider(
                    create: (context) => documentStorage,
                    dispose: (repository) => repository.dispose(),
                    child: BlocProvider(
                      create: (context) => ToolbarBloc(
                        toolRepository: context.read<ToolRepository>(),
                        selectionRepository:
                            context.read<SelectionRepository>(),
                        documentRepository:
                            context.read<DocumentRepository>(),
                      )..add(const RequestWatchToolbarStateEvent()),
                      child: Editor(documentRepository: documentRepository),
                    ),
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

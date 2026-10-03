import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

class SquiggleHomePage extends StatelessWidget {
  const SquiggleHomePage({
    super.key,
    required this.imageRepository,
    required this.context,
    required this.documentStorage,
    required this.documentLibraryRepository,
  });

  final ImageRepository imageRepository;
  final EditorContext context;
  final DocumentStorage documentStorage;
  final DocumentLibraryRepository documentLibraryRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: this.context,
        child: RepositoryProvider(
          create: (context) => imageRepository,
          dispose: (repository) => repository.dispose(),
          child: RepositoryProvider(
            create: (context) => documentStorage,
            child: RepositoryProvider(
              create: (context) => documentLibraryRepository,
              dispose: (repository) => repository.dispose(),
              child: AppShell(context: this.context),
            ),
          ),
        ),
      ),
    );
  }
}

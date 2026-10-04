import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.appRouter,
    required this.imageRepository,
    required this.context,
    required this.documentStorage,
    required this.documentLibraryRepository,
  });

  final AppRouter appRouter;
  final ImageRepository imageRepository;
  final EditorContext context;
  final DocumentStorage documentStorage;
  final DocumentLibraryRepository documentLibraryRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: this.context,
      child: RepositoryProvider(
        create: (context) => imageRepository,
        dispose: (repository) => repository.dispose(),
        child: RepositoryProvider(
          create: (context) => documentStorage,
          child: RepositoryProvider(
            create: (context) => documentLibraryRepository,
            dispose: (repository) => repository.dispose(),
            child: MaterialApp.router(
              title: 'Squiggle',
              theme: SquiggleThemeData.dark(),
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter.config(),
            ),
          ),
        ),
      ),
    );
  }
}

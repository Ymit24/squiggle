import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.appRouter,
    required this.imageRepository,
    required this.context,
    required this.database,
    required this.documentList,
    required this.activeDocument,
  });

  final AppRouter appRouter;
  final ImageRepository imageRepository;
  final EditorContext context;
  final AppDatabase database;
  final DocumentListNotifier documentList;
  final ActiveDocumentCoordinator activeDocument;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: this.context,
      child: RepositoryProvider(
        create: (context) => imageRepository,
        dispose: (repository) => repository.dispose(),
        child: RepositoryProvider(
          create: (context) => database,
          dispose: (database) => database.close(),
          child: RepositoryProvider(
            create: (context) => database.documentsDao,
            child: ChangeNotifierProvider(
              create: (context) => documentList,
              child: ChangeNotifierProvider(
                create: (context) => activeDocument,
                child: MaterialApp.router(
                  title: 'Squiggle',
                  theme: SquiggleThemeData.dark(),
                  debugShowCheckedModeBanner: false,
                  routerConfig: appRouter.config(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

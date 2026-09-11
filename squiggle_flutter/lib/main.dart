import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:window_manager/window_manager.dart';

String get _buildMode {
  if (kDebugMode) return 'DEBUG';
  if (kProfileMode) return 'PROFILE';
  return 'RELEASE';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.hide();

  final packageInfo = await PackageInfo.fromPlatform();
  final appTitle =
      'Squiggle - v${packageInfo.version}+${packageInfo.buildNumber} $_buildMode';

  final imageRepository = ImageRepository();
  await imageRepository.initialize();

  final documentStorage = DocumentStorage(imageRepository: imageRepository);
  final context = EditorContext(document: Document());
  final documentLibraryRepository = DocumentLibraryRepository(
    documentStorage: documentStorage,
    context: context,
  );
  await documentLibraryRepository.initialize();

  runApp(
    SquiggleApp(
      imageRepository: imageRepository,
      context: context,
      documentStorage: documentStorage,
      documentLibraryRepository: documentLibraryRepository,
      appTitle: appTitle,
    ),
  );

  await windowManager.waitUntilReadyToShow(WindowOptions(title: appTitle));
  await windowManager.show();
  await windowManager.focus();
}

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.imageRepository,
    required this.context,
    required this.documentStorage,
    required this.documentLibraryRepository,
    required this.appTitle,
  });

  final ImageRepository imageRepository;
  final EditorContext context;
  final DocumentStorage documentStorage;
  final DocumentLibraryRepository documentLibraryRepository;
  final String appTitle;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: SquiggleThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: SquiggleHomePage(
        imageRepository: imageRepository,
        context: this.context,
        documentStorage: documentStorage,
        documentLibraryRepository: documentLibraryRepository,
      ),
    );
  }
}

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
      body: RepositoryProvider(
        create: (context) => this.context,
        child: RepositoryProvider(
          create: (context) => imageRepository,
          dispose: (repository) => repository.dispose(),
          child: RepositoryProvider(
            create: (context) => documentStorage,
            child: RepositoryProvider(
              create: (context) => documentLibraryRepository,
              dispose: (repository) => repository.dispose(),
              child: BlocProvider(
                create: (context) =>
                    ToolbarBloc(context: this.context)
                      ..add(const RequestWatchToolbarStateEvent()),
                child: AppShell(context: this.context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

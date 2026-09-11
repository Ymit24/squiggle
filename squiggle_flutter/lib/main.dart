import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final packageInfo = await PackageInfo.fromPlatform();
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
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
    ),
  );
}

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.imageRepository,
    required this.context,
    required this.documentStorage,
    required this.documentLibraryRepository,
    required this.appVersion,
  });

  final ImageRepository imageRepository;
  final EditorContext context;
  final DocumentStorage documentStorage;
  final DocumentLibraryRepository documentLibraryRepository;
  final String appVersion;

  String get _buildMode {
    if (kDebugMode) return 'DEBUG';
    if (kProfileMode) return 'PROFILE';
    return 'RELEASE';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squiggle',
      theme: SquiggleThemeData.dark(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Banner(
          message: 'v$appVersion $_buildMode',
          location: BannerLocation.topStart,
          color: Theme.of(context).colorScheme.primary,
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          child: child!,
        );
      },
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

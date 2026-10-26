import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/database/open_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:window_manager/window_manager.dart';

String get _buildMode {
  if (kDebugMode) return 'DEBUG';
  if (kProfileMode) return 'PROFILE';
  return 'RELEASE';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();
  final appTitle =
      'Squiggle - v${packageInfo.version}+${packageInfo.buildNumber} $_buildMode';
  await windowManager.setTitle(appTitle);
  await windowManager.setMinimumSize(const Size(640, 480));

  final database = await openAppDatabase();
  final imageRepository = ImageRepository(images: database.imagesDao);

  // Safe now: nothing has loaded a document yet, so no undo history can bring
  // back a reference to an image only this sweep would remove.
  await database.imagesDao.deleteUnreferenced();

  final context = EditorContext(document: Document());
  final documentList = DocumentListNotifier(
    documentsDao: database.documentsDao,
  );
  final activeDocument = ActiveDocumentCoordinator(
    documentsDao: database.documentsDao,
    appStateDao: database.appStateDao,
    documentList: documentList,
    context: context,
  );
  await activeDocument.initialize();

  final appRouter = AppRouter();

  runApp(
    SquiggleApp(
      appRouter: appRouter,
      imageRepository: imageRepository,
      context: context,
      database: database,
      documentList: documentList,
      activeDocument: activeDocument,
    ),
  );
}

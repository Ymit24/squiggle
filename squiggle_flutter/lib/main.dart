import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
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
    ),
  );
}

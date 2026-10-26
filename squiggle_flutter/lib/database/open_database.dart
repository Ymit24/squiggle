import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// Opens the app database in the application support directory.
Future<AppDatabase> openAppDatabase() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final directory = Directory('${supportDirectory.path}/Squiggle');
  await directory.create(recursive: true);
  return AppDatabase.file(File('${directory.path}/squiggle.db'));
}

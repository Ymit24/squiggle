import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// The folder holding the database and, from before the database, the
/// `documents/` and `images/` files.
Future<Directory> legacyStorageDirectory() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return Directory('${supportDirectory.path}/Squiggle');
}

/// Opens the app database in the application support directory.
Future<AppDatabase> openAppDatabase() async {
  final directory = await legacyStorageDirectory();
  await directory.create(recursive: true);
  return AppDatabase.file(File('${directory.path}/squiggle.db'));
}

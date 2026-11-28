import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/open_database_native.dart'
    if (dart.library.js_interop) 'package:squiggle_flutter/database/open_database_web.dart'
    as platform;

/// Opens the platform's persistent app database.
Future<AppDatabase> openAppDatabase() => platform.openAppDatabase();

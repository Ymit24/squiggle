import 'package:drift/native.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// A fresh in-memory database; close it in `tearDown`.
AppDatabase createTestDatabase() => AppDatabase(NativeDatabase.memory());

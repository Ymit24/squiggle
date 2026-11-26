import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// A fresh in-memory database; close it in `tearDown`.
///
/// Query streams close synchronously so widget tests don't leave drift's
/// deferred-cleanup timers pending after the widget tree is disposed.
AppDatabase createTestDatabase() => AppDatabase(
  DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,
  ),
);

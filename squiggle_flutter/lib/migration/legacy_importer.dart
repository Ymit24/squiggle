import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// What a [LegacyImporter] run did.
class MigrationReport {
  int images = 0;
  int documentsImported = 0;
  int documentsAlreadyImported = 0;
  int imageNodesDropped = 0;
  final List<String> problems = [];
}

/// One-off import of the file-based storage (`documents/*.json`, `images/*`,
/// `active_document.txt`) into the database.
///
/// The old files are only read. Each imported document gets a fresh UUID,
/// recorded as `legacy:<old id>` in `AppState` so a second run skips it; wipe
/// the database to start over.
class LegacyImporter {
  LegacyImporter({required this.legacyRoot, required this.database});

  final Directory legacyRoot;
  final AppDatabase database;

  static const _markerPrefix = 'legacy:';

  /// Whether [legacyRoot] has old documents to import.
  Future<bool> hasLegacyDocuments() async {
    final directory = Directory('${legacyRoot.path}/documents');
    if (!await directory.exists()) return false;
    return directory.list().any((e) => e is File && e.path.endsWith('.json'));
  }

  Future<MigrationReport> run() async {
    final report = MigrationReport();
    final hashes = await _importImages(report);
    final newIds = await _importDocuments(hashes, report);
    await _restoreActiveDocument(newIds);
    return report;
  }

  /// Old image id (file name) to the sha256 hex id the image is stored under.
  Future<Map<String, String>> _importImages(MigrationReport report) async {
    final hashes = <String, String>{};
    final directory = Directory('${legacyRoot.path}/images');
    if (!await directory.exists()) return hashes;

    await for (final entity in directory.list()) {
      if (entity is! File || entity.path.endsWith('.tmp')) continue;
      final oldId = entity.uri.pathSegments.last;
      final bytes = await entity.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      await database.imagesDao.insertIfAbsent(hash, bytes);
      hashes[oldId] = hash;
      report.images++;
    }
    return hashes;
  }

  /// Old document id to new document id, for documents imported by any run.
  Future<Map<String, String>> _importDocuments(
    Map<String, String> hashes,
    MigrationReport report,
  ) async {
    final newIds = <String, String>{};
    final directory = Directory('${legacyRoot.path}/documents');
    if (!await directory.exists()) return newIds;

    final files = await directory
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    for (final file in files) {
      final oldId = file.uri.pathSegments.last.replaceAll('.json', '');
      final existing = await _marker(oldId);
      if (existing != null) {
        newIds[oldId] = existing;
        report.documentsAlreadyImported++;
        continue;
      }

      try {
        newIds[oldId] = await _importDocument(file, oldId, hashes, report);
        report.documentsImported++;
      } on Object catch (error) {
        report.problems.add('$oldId: $error');
      }
    }
    return newIds;
  }

  Future<String> _importDocument(
    File file,
    String oldId,
    Map<String, String> hashes,
    MigrationReport report,
  ) async {
    final old = data.Document.decode(await file.readAsString());
    final document = data.Document(
      name: old.name,
      nodes: _rewriteImageIds(old.nodes, hashes, report),
      session: old.session,
    );
    final modified = file.statSync().modified;

    return database.transaction(() async {
      final info = await database.documentsDao.create(name: document.name);
      await database.documentsDao.save(info.id, document);
      await (database.update(
        database.documentMetadatas,
      )..where((t) => t.id.equals(info.id))).write(
        DocumentMetadatasCompanion(
          createdAt: Value(modified),
          updatedAt: Value(modified),
        ),
      );
      await database
          .into(database.appState)
          .insertOnConflictUpdate(
            AppStateCompanion.insert(
              key: '$_markerPrefix$oldId',
              value: info.id,
            ),
          );
      return info.id;
    });
  }

  /// Rewrites image ids to hash ids. An image whose file is missing cannot
  /// satisfy the foreign key, so its node is left out (it never rendered).
  List<data.Node> _rewriteImageIds(
    List<data.Node> nodes,
    Map<String, String> hashes,
    MigrationReport report,
  ) {
    final rewritten = <data.Node>[];
    for (final node in nodes) {
      switch (node) {
        case data.Group():
          rewritten.add(
            data.Group(
              id: node.id,
              originX: node.originX,
              originY: node.originY,
              children: _rewriteImageIds(node.children, hashes, report),
            ),
          );
        case data.Feature(:final content) when content['type'] == 'image':
          final hash = hashes[content['imageId']];
          if (hash == null) {
            report.imageNodesDropped++;
            continue;
          }
          rewritten.add(
            data.Feature(
              id: node.id,
              originX: node.originX,
              originY: node.originY,
              width: node.width,
              height: node.height,
              content: {...content, 'imageId': hash},
            ),
          );
        default:
          rewritten.add(node);
      }
    }
    return rewritten;
  }

  Future<void> _restoreActiveDocument(Map<String, String> newIds) async {
    final file = File('${legacyRoot.path}/active_document.txt');
    if (!await file.exists()) return;
    final newId = newIds[(await file.readAsString()).trim()];
    if (newId != null) {
      await database.appStateDao.setActiveDocumentId(newId);
    }
  }

  Future<String?> _marker(String oldId) async {
    final row = await (database.select(
      database.appState,
    )..where((t) => t.key.equals('$_markerPrefix$oldId'))).getSingleOrNull();
    return row?.value;
  }
}

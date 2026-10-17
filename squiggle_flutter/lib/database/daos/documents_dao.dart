import 'package:data_models/data_models.dart' as data;
import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/image_references.dart';
import 'package:squiggle_flutter/database/tables/documents.dart';
import 'package:squiggle_flutter/database/tables/images.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:uuid/uuid.dart';

part 'documents_dao.g.dart';

/// Documents are identified by [DocumentMetadatas.id]. The
/// [DocumentMetadatas.name] column is the source of truth for a document's
/// name; the name inside the stored body is ignored on load.
@DriftAccessor(tables: [DocumentMetadatas, DocumentBodies, ImageRefs])
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.attachedDatabase);

  /// Document metadata, most recently updated first. Never reads bodies.
  Future<List<DocumentInfo>> list() async {
    final rows = await (select(
      documentMetadatas,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(_toInfo).toList();
  }

  /// Creates an empty document named [name].
  Future<DocumentInfo> create({required String name}) {
    final now = attachedDatabase.clock();
    final id = const Uuid().v4();
    return transaction(() async {
      await into(documentMetadatas).insert(
        DocumentMetadatasCompanion.insert(
          id: id,
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _writeBody(id, data.Document(name: name));
      return DocumentInfo(id: id, name: name, updatedAt: now);
    });
  }

  /// Returns the document, or null if [id] does not exist.
  ///
  /// Throws if the stored body cannot be decoded; callers decide how to
  /// surface that, and the stored row is left untouched.
  Future<data.Document?> load(String id) async {
    final query = select(documentMetadatas).join([
      innerJoin(
        documentBodies,
        documentBodies.documentId.equalsExp(documentMetadatas.id),
      ),
    ])..where(documentMetadatas.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final stored = data.Document.decode(row.read(documentBodies.body)!);
    return data.Document(
      name: row.read(documentMetadatas.name)!,
      nodes: stored.nodes,
      session: stored.session,
    );
  }

  /// Replaces the body and image references of [id] and bumps `updatedAt`.
  ///
  /// The name inside [document] is ignored; use [rename]. Does nothing if
  /// [id] no longer exists, e.g. an autosave racing a delete.
  Future<void> save(String id, data.Document document) {
    return transaction(() async {
      final updated =
          await (update(
            documentMetadatas,
          )..where((t) => t.id.equals(id))).write(
            DocumentMetadatasCompanion(
              updatedAt: Value(attachedDatabase.clock()),
            ),
          );
      if (updated == 0) {
        return;
      }

      await _writeBody(id, document);
      await (delete(imageRefs)..where((t) => t.documentId.equals(id))).go();
      await batch(
        (batch) => batch.insertAll(imageRefs, [
          for (final hash in imageHashesIn(document.nodes))
            ImageRefsCompanion.insert(documentId: id, imageHash: hash),
        ]),
      );
    });
  }

  Future<void> rename(String id, String name) =>
      (update(documentMetadatas)..where((t) => t.id.equals(id))).write(
        DocumentMetadatasCompanion(
          name: Value(name),
          updatedAt: Value(attachedDatabase.clock()),
        ),
      );

  /// Deletes the document and, by cascade, its body and image references.
  Future<void> remove(String id) =>
      (delete(documentMetadatas)..where((t) => t.id.equals(id))).go();

  Future<void> _writeBody(String id, data.Document document) =>
      into(documentBodies).insertOnConflictUpdate(
        DocumentBodiesCompanion.insert(
          documentId: id,
          formatVersion: data.dataModelFormatVersion,
          body: document.encode(),
        ),
      );

  DocumentInfo _toInfo(DocumentMetadata row) =>
      DocumentInfo(id: row.id, name: row.name, updatedAt: row.updatedAt);
}

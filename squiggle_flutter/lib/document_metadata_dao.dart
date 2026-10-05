import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database.dart';

part 'document_metadata_dao.g.dart';

@DriftAccessor(tables: [DocumentMetadatas])
class DocumentMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentMetadataDaoMixin {
  DocumentMetadataDao(super.attachedDatabase);

  Future<List<DocumentMetadata>> all() {
    return select(documentMetadatas).get();
  }

  Future<int> create(String name) {
    return into(
      documentMetadatas,
    ).insert(DocumentMetadatasCompanion(name: Value(name)));
  }

  Future<void> rename(int id, String name) async {
    final now = DateTime.now().toUtc();

    final query = update(documentMetadatas)..where((tbl) => tbl.id.equals(id));

    await query.write(
      DocumentMetadatasCompanion(name: Value(name), updatedAt: Value(now)),
    );
  }

  Future<void> destroy(int id) async {
    final query = delete(documentMetadatas)
      ..where((table) => table.id.equals(id));

    await query.go();
  }
}

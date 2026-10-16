import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/tables/documents.dart';
import 'package:squiggle_flutter/database/tables/images.dart';

part 'images_dao.g.dart';

@DriftAccessor(tables: [Images, ImageRefs, Documents])
class ImagesDao extends DatabaseAccessor<AppDatabase> with _$ImagesDaoMixin {
  ImagesDao(super.attachedDatabase);

  /// Stores [bytes] under [hash], the sha256 hex digest of [bytes].
  ///
  /// The caller computes the hash; an existing image is left untouched.
  Future<void> insertIfAbsent(String hash, Uint8List bytes) =>
      into(images).insert(
        ImagesCompanion.insert(
          hash: hash,
          bytes: bytes,
          createdAt: attachedDatabase.clock(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<Uint8List?> bytes(String hash) async {
    final query = selectOnly(images)
      ..addColumns([images.bytes])
      ..where(images.hash.equals(hash));
    final row = await query.getSingleOrNull();
    return row?.read(images.bytes);
  }

  /// Deletes images no document references and returns how many were removed.
  ///
  /// Only safe when no editor holds undo history that could bring a
  /// reference back, so call it at startup rather than during editing.
  Future<int> deleteUnreferenced() => customUpdate(
    'DELETE FROM images WHERE hash NOT IN (SELECT image_hash FROM image_refs)',
    updates: {images},
    updateKind: UpdateKind.delete,
  );
}

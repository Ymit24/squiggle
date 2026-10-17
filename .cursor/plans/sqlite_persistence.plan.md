---
name: SQLite Persistence (drift)
overview: Port persistence from per-document JSON files + PNG files to a single SQLite DB via drift, delivered as a stack of small PRs. Non-DB refactors go first and are each mergeable on their own; the DB work follows.
todos:
  - id: pr1-clipboard-image-io
    content: "PR 1: Move clipboard image reading out of ImageRepository into services/clipboard.dart (pure move)"
    status: pending
  - id: pr2-rename-image-cache
    content: "PR 2: Rename ImageRepository to the decode-cache name (mechanical, ~60 files, own PR). Deferred until the cache-provision design is settled."
    status: pending
  - id: pr3-image-store-hash-ids
    content: "PR 3: Split decode cache from a file-backed ImageStore; ids become sha256 of bytes (adds crypto dep)"
    status: pending
  - id: pr4-reshape-document-storage
    content: "PR 4: DROPPED. Subsumed by PR 8 (DocumentStorage is replaced by DocumentsDao, which already has UUID ids and a metadata-only list)."
    status: cancelled
  - id: pr5-split-library-repository
    content: "PR 5: Split DocumentLibraryRepository into list notifier + active-document coordinator"
    status: pending
  - id: pr6-drift-schema
    content: "PR 6: Drift schema + DAOs, additive and not wired in (design sign-off point). This is the feature branch itself (#162)."
    status: completed
  - id: pr7-images-on-db
    content: "PR 7: Images onto the DB (ImageStore becomes ImagesDao), startup GC"
    status: pending
  - id: pr8-documents-on-db
    content: "PR 8: Documents onto the DB, previewPng column, startup image GC, failed-load policy, delete file code and obsolete tests"
    status: pending
  - id: pr9-migration-screen
    content: "PR 9: Temporary migration debug screen (throwaway branch, never merged to main)"
    status: pending
isProject: false
---

# SQLite Persistence (drift)

Status: PR 6 (schema and DAOs) is the feature branch `t3/sqlite-drift-persistence-port` (PR #162 into `main`). Every other PR targets that branch, and the whole port merges to `main` once.

## PR stack

### Phase 1: no DB, each PR mergeable on its own

| # | PR | Notes |
|---|---|---|
| 1 | Move clipboard image reading out of `ImageRepository` into `services/clipboard.dart` | Pure move |
| 2 | Rename `ImageRepository` to the decode-cache name | **Deferred** until the cache-provision design is settled (it likely touches the same ~60 call sites). Mechanical, ~60 files. Own PR so nobody reads logic inside a rename. Avoid the name `ImageCache` (clashes with Flutter); candidates `DecodedImages` / `CanvasImages`. |
| 3 | Split the cache from a file-backed `ImageStore` (`put(bytes)` returns an id, `get(id)`), and make ids the sha256 of the bytes | Adds `crypto`. Dedupes pastes. Old `img_..png` ids still load (files are named by id). The `importedIds` remapping in the clipboard path stays: payloads and documents still containing old `img_..png` ids need them rewritten to hash ids on paste. It can go once the migration has rewritten everything. `ImageStore` resolves its directory lazily, so `ImageRepository.initialize()` is gone. |
| 4 | Reshape the `DocumentStorage` API in place | Drop `StoredDocument` and the unused `imageRepository` field. Make `listDocuments` a metadata-only call shape. Remove the `initialize()` ceremony. Document ids become `const Uuid().v4()` (replaces `_generateDocumentId`); backward compatible, existing `doc_..json` files keep loading. |
| 5 | Split `DocumentLibraryRepository` into a list notifier and an active-document coordinator | No re-list per autosave, list refreshed on entering the library screen, flush on document switch. |

No interface with a file implementation and a DB implementation: PRs 3 and 4 change the API directly, since only one implementation remains after the swap. Tests move to an in-memory DB.

### Phase 2: DB

| # | PR | Notes |
|---|---|---|
| 6 | Drift schema + DAOs, additive and not wired in | Design sign-off point. Large generated diff; review the hand-written files in `lib/database/` only. Commit `*.g.dart` like the existing freezed files. |
| 7 | Images onto the DB (`ImageStore` becomes `ImagesDao`) | Small because PR 3 fixed the shape. Opens the DB file (path via `path_provider`). Must await `insertIfAbsent` before the node referencing the image exists (FK). No GC here: `image_refs` is empty until documents are on the DB. Must come before 8 because of the FK. |
| 8 | Documents onto the DB, `previewPng` column, startup image GC, delete the file code and obsolete tests | Absorbs old PR 4. Gate: decide the failed-load policy first. Old documents and images are not visible until the migration runs. |
| 9 | Temporary migration screen | Throwaway branch, never merged to `main`. |

### Notes on ordering

- **Branching:** the feature branch `t3/sqlite-drift-persistence-port` is the integration branch (PR #162, retitled as the umbrella). Each sub-PR is its own branch opened against it; later sub-PRs rebase onto it after earlier ones merge. One merge to `main` at the end, so intermediate states never release.
- Order: 1, 3, 5, then 7, then 8. 2 is deferred. 7 before 8 because `image_refs.image_hash` is a foreign key to `images.hash`.
- PRs 3 and 5 shape the API from the DAO sketch below before it is wired in. If a mismatch shows up, touch up the earlier API in the DB PRs.
- **Gates before PR 8:** (a) decide the failed-load policy (see Deferred); (b) real-data check: a throwaway migration run into an on-disk DB against the real documents, to confirm save time on the largest document and that nothing trips the FK; (c) `flutter build linux --release` once on the branch to confirm the bundled SQLite compiles.
- Validation per PR (from `squiggle_flutter/AGENTS.md`): `flutter analyze`, `dart run dart_code_linter:metrics analyze lib packages/data_models/lib test`, plus relevant tests. Semantic commits.

## Decisions

- **Document ids:** UUID v4 as text (`uuid` is already a dependency; `BrushController` uses it). Not autoincrement: SQLite reuses the max rowid after deleting the newest row, so a stale active-document id could point at a different document, and the insert would need a round trip to learn the id. The old `doc_<µs>_<hex>` scheme only existed to be filename-safe; sorting uses `updatedAt`, not the id.
- **Row granularity (option C):** per-document row with real metadata columns plus a body column holding `data.Document.encode()`. Moving to normalized nodes with incremental autosave is a later effort alongside the history rework; `save(id, doc)` is the single seam that can later become `applyChanges(id, changes)`.
- **Autosave:** stays a whole-body write for now. Keep a minimal serialized write queue and flush on document switch. No debounce / window-close flush in this port.
- **Images:** raw `BlobColumn` bytes (base64 only at the clipboard boundary). Content hash (sha256 hex) is the id and the value stored in `FeatureKindImage.imageId`. Images are immutable. Separate `Images` table, never selected in list queries. GC of unreferenced images at startup only (never on node removal/save, or undo could point at a vanished image).
- **Decode cache:** stays, because painting is synchronous (`getCached`/`requestImage`/`repaintStream`) and the DB only yields bytes. Loads from `ImagesDao`, no I/O of its own. How the cache reaches painters (about 60 call sites threading it through) is a separate design question, not bundled here.
- **Library list:** imperative, no `watch()`. The list can only change on create/rename/delete while the library screen is shown. `listDocuments()` is a metadata-only query that never touches bodies.
- **Previews:** nullable `previewPng` column, left null for now. `DocumentPreviewLoader` keeps its lazy body load as the fallback when null. Real thumbnails come later.
- **Repositories dissolve into:** drift DAOs (replace `DocumentStorage` / `StoredDocument`), the decode cache, clipboard image reading in `services/clipboard.dart`, a list notifier, and an active-document coordinator.
- **Migration:** none in the shipped app. Temporary debug screen set as the root route reads the old `<support>/Squiggle/documents/*.json`, `images/*`, `active_document.txt`, rewrites image ids to hashes (walking `Feature.content`, recursing into groups), mints a fresh UUID v4 per document (keeping an old-id to new-id map so `active_document.txt` still resolves) and sets `updatedAt` from file mtime. Old files are left untouched, so the DB can be wiped and re-run. Own commit, deleted after use.
- **Spike:** not needed. Verify drift in the Linux debug app, `flutter build linux --release` in `linux-release.yml`, and in-memory DB under `flutter test` on the CI runner as part of implementation.

## Schema sketch

`lib/database/` (app side; `packages/data_models` stays Flutter- and DB-free and remains the codec).

```dart
class DocumentMetadatas extends Table {          // row class DocumentMetadata, SQL table `document_metadata`
  TextColumn get id => text()();                 // UUID v4, generated in Dart by DocumentsDao.create
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();  // explicit, no longer file mtime
  BlobColumn get previewPng => blob().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class DocumentBodies extends Table {            // split out so list queries never touch it
  TextColumn get documentId =>
      text().references(DocumentMetadatas, #id, onDelete: KeyAction.cascade)();
  IntColumn get formatVersion => integer()();
  TextColumn get body => text()();               // data.Document.encode()
  @override Set<Column> get primaryKey => {documentId};
}

class Images extends Table {
  TextColumn get hash => text()();               // sha256 hex, also FeatureKindImage.imageId
  BlobColumn get bytes => blob()();
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {hash};
}

class ImageRefs extends Table {                  // rebuilt in the same transaction as each save
  TextColumn get documentId =>
      text().references(DocumentMetadatas, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageHash => text().references(Images, #hash)();  // FK: store the image before saving a doc that uses it
  @override Set<Column> get primaryKey => {documentId, imageHash};
}

class AppState extends Table {                   // replaces active_document.txt
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override Set<Column> get primaryKey => {key};
}
```

DAO surface:

```dart
@DriftAccessor(tables: [DocumentMetadatas, DocumentBodies, ImageRefs])
class DocumentsDao extends DatabaseAccessor<AppDatabase> {
  Future<List<DocumentInfo>> list();                  // metadata only, never touches bodies
  Future<DocumentInfo> create({String? name});
  Future<data.Document?> load(String id);             // return type can grow (failed-load policy)
  Future<void> save(String id, data.Document doc);    // body + updatedAt + ImageRefs, one transaction
  Future<void> rename(String id, String name);        // UPDATE, not read-modify-write
  Future<void> remove(String id);                     // not `delete`: clashes with DatabaseAccessor.delete(table)
}

@DriftAccessor(tables: [Images])
class ImagesDao extends DatabaseAccessor<AppDatabase> {
  Future<void> insertIfAbsent(String hash, Uint8List bytes); // caller hashes (keeps crypto out of the DAO)
  Future<Uint8List?> bytes(String hash);
  Future<void> deleteUnreferenced();                  // startup GC only
}
```

## Implementation checklist for the DB PRs

- `PRAGMA foreign_keys = ON` in drift's `beforeOpen`, otherwise cascade deletes silently do nothing. WAL mode; `busy_timeout` if multiple instances matter.
- Two version layers: drift `schemaVersion` for tables, `DocumentBodies.formatVersion` + JSON upgrade functions for payloads (replaces today's hard `throw` when `version != 2`).
- Drift schema dump baseline is committed (`drift_schemas/drift_schema_v1.json`, done in PR 6). When `schemaVersion` first bumps, dump v2 and add generated migration tests (`dart run drift_dev schema generate`).
- Existing tests to drop: temp-dir setup, "writes version 2 and rejects older versions" (file-level), `.png` filename/directory tests in `image_repository_test.dart`.
- Existing tests to keep (ported to `NativeDatabase.memory()`): CRUD round trip, brush snapshot ordering (exercises the write queue), clipboard tests (simplified by hash ids).
- Tests to add: image dedupe, cascade delete, schema migration, and (once decided) failed load does not overwrite the original.

## Learned while implementing PR 6

- `drift_dev` >= 2.34.6 needs `analyzer` >= 13, which `freezed` 3.x could not resolve against and `freezed` 4 needs Dart 3.13. Resolved by PR #164 (Flutter 3.47.7 / Dart 3.13, `freezed` 4); `drift` and `drift_dev` are unpinned (`^2.35`).
- `sqlite3_flutter_libs` is end-of-life and not needed: `sqlite3` 3.x bundles the native library via build hooks. `flutter test` on Linux opens in-memory and file DBs with no extra setup.
- Timestamps use drift's default (whole-second unix integers). Text mode was tried and dropped: it stores local time with an offset (`... -04:00`), and SQLite sorts that as a string, so ordering breaks across DST/timezone changes. Same-second ties in `updatedAt` are not a real concern for this app. `generate_for` is limited to `lib/database/**` in `build.yaml` to keep build_runner from scanning every file.
- Table row classes use `@DataClassName(...Row)` to avoid clashing with the app and data_models `Document`.
- The `name` column is authoritative: `save` ignores the name in the document, and `load` overrides the stored body's name with the column.
- `load` returns null only for an unknown id and throws if the body cannot be decoded (policy still deferred, see below). `save` on a deleted document is a silent no-op (autosave racing a delete).
- `AppDatabase` takes an injectable `clock` so tests control `updatedAt` ordering.
- The database location (path_provider) is deliberately not in PR 6; `AppDatabase.file(File)` is, and wiring picks the path in PR 7/8.

## Deferred / open

- **Failed-load policy.** Today a decode failure loads an empty `Document()` and the next autosave overwrites the original. Wants an error surface and no autosave over an unreadable doc. Undecided; keep `DocumentsDao.load` return type extensible.
- Incremental autosave and history dirty tracking (option B, normalized `nodes` table).
- Real preview thumbnails.
- How the decode cache is provided to painters (the ~60-site parameter threading).
- Multiple app instances sharing one DB; `-wal`/`-shm` sidecar files if the folder is synced.

## Review changes to PR 6

- `Documents` renamed `DocumentMetadatas` (row `DocumentMetadata`, SQL table `document_metadata`); `DocumentBodies` row is `DocumentBody`.
- `ImageRefs.imageHash` now has a foreign key to `Images.hash`. A save that references an image that was not stored first fails and rolls back. Consequences for later PRs: the image store must `insertIfAbsent` (awaited) before the node referencing it is created, and the one-off migration must handle JSON documents whose PNG file is missing.

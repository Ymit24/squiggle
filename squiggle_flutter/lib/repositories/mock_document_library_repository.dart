import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';

/// In-memory placeholder with one document for DI and UI previews.
class MockDocumentLibraryRepository implements DocumentLibraryRepository {
  static final _mockDocument = DocumentInfo(
    id: 'mock-document',
    name: 'Mock document',
    updatedAt: DateTime.utc(2024),
  );

  @override
  List<DocumentInfo> get documents => List.unmodifiable([_mockDocument]);

  @override
  DocumentInfo get currentDocument => _mockDocument;

  @override
  Stream<void> get changesStream => const Stream<void>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> createDocument({String? name}) async {}

  @override
  Future<void> openDocument(String id) async {}

  @override
  Future<void> refreshDocuments() async {}

  @override
  Future<void> saveCurrentDocument() async {}

  @override
  Future<void> renameDocument(String id, String newName) async {}

  @override
  Future<void> deleteDocument(String id) async {}

  @override
  void dispose() {}
}

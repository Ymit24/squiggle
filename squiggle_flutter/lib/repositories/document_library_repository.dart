import 'package:squiggle_flutter/models/document_info.dart';

/// Manages the set of documents available to the editor and library UI.
abstract interface class DocumentLibraryRepository {
  List<DocumentInfo> get documents;
  DocumentInfo? get currentDocument;
  Stream<void> get changesStream;

  Future<void> initialize();
  Future<void> createDocument({String? name});
  Future<void> openDocument(String id);
  Future<void> refreshDocuments();
  Future<void> saveCurrentDocument();
  Future<void> renameDocument(String id, String newName);
  Future<void> deleteDocument(String id);

  void dispose();
}

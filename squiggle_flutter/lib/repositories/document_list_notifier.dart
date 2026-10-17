import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';

/// The list of persisted documents shown in the library.
///
/// The list is only re-read on [refresh], which callers invoke when it can
/// have changed (structural edits and entering the library screen). Autosaves
/// do not touch it.
class DocumentListNotifier extends ChangeNotifier {
  DocumentListNotifier({required this.documentStorage});

  final DocumentStorage documentStorage;

  List<DocumentInfo> _documents = const [];
  int _refreshGeneration = 0;

  List<DocumentInfo> get documents => _documents;

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    final documents = await documentStorage.listDocuments();
    // A newer refresh started while this one was reading; its result wins.
    if (generation != _refreshGeneration) return;
    _documents = List.unmodifiable(documents);
    notifyListeners();
  }
}

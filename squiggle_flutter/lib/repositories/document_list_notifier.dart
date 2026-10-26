import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/models/document_info.dart';

/// The list of persisted documents shown in the library.
///
/// The list is only re-read on [refresh], which callers invoke when it can
/// have changed (structural edits and entering the library screen). Autosaves
/// do not touch it.
class DocumentListNotifier extends ChangeNotifier {
  DocumentListNotifier({required this.documentsDao});

  final DocumentsDao documentsDao;

  static const _defaultDocumentName = 'Untitled';

  List<DocumentInfo> _documents = const [];
  int _refreshGeneration = 0;

  List<DocumentInfo> get documents => _documents;

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    final documents = await documentsDao.list();
    // A newer refresh started while this one was reading; its result wins.
    if (generation != _refreshGeneration) return;
    _documents = List.unmodifiable(documents);
    notifyListeners();
  }

  /// "Untitled", or "Untitled 2", "Untitled 3", ... when taken.
  String nextUntitledName() {
    final usedNames = _documents.map((document) => document.name).toSet();
    if (!usedNames.contains(_defaultDocumentName)) {
      return _defaultDocumentName;
    }

    var index = 2;
    while (usedNames.contains('$_defaultDocumentName $index')) {
      index++;
    }
    return '$_defaultDocumentName $index';
  }
}

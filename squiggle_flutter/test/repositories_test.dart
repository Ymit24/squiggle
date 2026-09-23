import 'package:flutter_test/flutter_test.dart';

import 'repositories/document_library_repository_cases.dart' as document_library_repository;
import 'repositories/document_storage_cases.dart' as document_storage;
import 'repositories/image_repository_cases.dart' as image_repository;
import 'repositories/selection_cases.dart' as selection;

void main() {
  group('repositories/document_library_repository', document_library_repository.main);
  group('repositories/document_storage', document_storage.main);
  group('repositories/image_repository', image_repository.main);
  group('repositories/selection', selection.main);
}

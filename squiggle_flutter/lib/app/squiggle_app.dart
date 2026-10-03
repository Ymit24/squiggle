import 'package:flutter/material.dart';
import 'package:squiggle_flutter/app/squiggle_home_page.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleApp extends StatelessWidget {
  const SquiggleApp({
    super.key,
    required this.imageRepository,
    required this.context,
    required this.documentStorage,
    required this.documentLibraryRepository,
  });

  final ImageRepository imageRepository;
  final EditorContext context;
  final DocumentStorage documentStorage;
  final DocumentLibraryRepository documentLibraryRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squiggle',
      theme: SquiggleThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: SquiggleHomePage(
        imageRepository: imageRepository,
        context: this.context,
        documentStorage: documentStorage,
        documentLibraryRepository: documentLibraryRepository,
      ),
    );
  }
}

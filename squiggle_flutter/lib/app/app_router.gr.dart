// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DocumentLibraryPage]
class DocumentLibraryRoute extends PageRouteInfo<DocumentLibraryRouteArgs> {
  DocumentLibraryRoute({
    Key? key,
    required Future<void> Function(String) onOpenDocument,
    required Future<void> Function({String? name}) onCreateAndOpen,
    List<PageRouteInfo>? children,
  }) : super(
         DocumentLibraryRoute.name,
         args: DocumentLibraryRouteArgs(
           key: key,
           onOpenDocument: onOpenDocument,
           onCreateAndOpen: onCreateAndOpen,
         ),
         initialChildren: children,
       );

  static const String name = 'DocumentLibraryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DocumentLibraryRouteArgs>();
      return DocumentLibraryPage(
        key: args.key,
        onOpenDocument: args.onOpenDocument,
        onCreateAndOpen: args.onCreateAndOpen,
      );
    },
  );
}

class DocumentLibraryRouteArgs {
  const DocumentLibraryRouteArgs({
    this.key,
    required this.onOpenDocument,
    required this.onCreateAndOpen,
  });

  final Key? key;

  final Future<void> Function(String) onOpenDocument;

  final Future<void> Function({String? name}) onCreateAndOpen;

  @override
  String toString() {
    return 'DocumentLibraryRouteArgs{key: $key, onOpenDocument: $onOpenDocument, onCreateAndOpen: $onCreateAndOpen}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentLibraryRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [Editor]
class Editor extends PageRouteInfo<EditorArgs> {
  Editor({
    Key? key,
    required EditorContext editorContext,
    required VoidCallback onBackToLibrary,
    List<PageRouteInfo>? children,
  }) : super(
         Editor.name,
         args: EditorArgs(
           key: key,
           editorContext: editorContext,
           onBackToLibrary: onBackToLibrary,
         ),
         initialChildren: children,
       );

  static const String name = 'Editor';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditorArgs>();
      return Editor(
        key: args.key,
        editorContext: args.editorContext,
        onBackToLibrary: args.onBackToLibrary,
      );
    },
  );
}

class EditorArgs {
  const EditorArgs({
    this.key,
    required this.editorContext,
    required this.onBackToLibrary,
  });

  final Key? key;

  final EditorContext editorContext;

  final VoidCallback onBackToLibrary;

  @override
  String toString() {
    return 'EditorArgs{key: $key, editorContext: $editorContext, onBackToLibrary: $onBackToLibrary}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditorArgs) return false;
    return key == other.key &&
        editorContext == other.editorContext &&
        onBackToLibrary == other.onBackToLibrary;
  }

  @override
  int get hashCode =>
      key.hashCode ^ editorContext.hashCode ^ onBackToLibrary.hashCode;
}

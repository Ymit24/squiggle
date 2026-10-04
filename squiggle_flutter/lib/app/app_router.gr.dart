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
class DocumentLibraryRoute extends PageRouteInfo<void> {
  const DocumentLibraryRoute({List<PageRouteInfo>? children})
    : super(DocumentLibraryRoute.name, initialChildren: children);

  static const String name = 'DocumentLibraryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DocumentLibraryPage();
    },
  );
}

/// generated route for
/// [EditorPage]
class EditorRoute extends PageRouteInfo<EditorRouteArgs> {
  EditorRoute({Key? key, required String id, List<PageRouteInfo>? children})
    : super(
        EditorRoute.name,
        args: EditorRouteArgs(key: key, id: id),
        rawPathParams: {'id': id},
        initialChildren: children,
      );

  static const String name = 'EditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditorRouteArgs>(
        orElse: () => EditorRouteArgs(id: pathParams.getString('id')),
      );
      return EditorPage(key: args.key, id: args.id);
    },
  );
}

class EditorRouteArgs {
  const EditorRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'EditorRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditorRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

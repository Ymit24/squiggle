import 'package:auto_route/auto_route.dart';
import 'package:squiggle_flutter/document_library/document_library_page.dart';
import 'package:squiggle_flutter/editor/editor.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  // TODO: implement routes
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/documents',
      page: DocumentLibraryRoute.page,
      initial: true,
    ),
    AutoRoute(path: '/documents/:id', page: EditorRoute.page),
  ];
}

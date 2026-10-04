import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/document_library_page.dart';
import 'package:squiggle_flutter/editor/editor_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    CustomRoute(
      path: '/documents',
      page: DocumentLibraryRoute.page,
      initial: true,
      transitionsBuilder: TransitionsBuilders.noTransition,
    ),
    CustomRoute(
      path: '/documents/:id',
      page: EditorRoute.page,
      transitionsBuilder: TransitionsBuilders.noTransition,
    ),
  ];
}

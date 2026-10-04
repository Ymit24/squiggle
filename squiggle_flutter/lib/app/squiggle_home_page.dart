import 'package:flutter/material.dart';
import 'package:squiggle_flutter/app/app_shell.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';

class SquiggleHomePage extends StatelessWidget {
  const SquiggleHomePage({super.key, required this.context});

  final EditorContext context;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: AppShell(editorContext: this.context));
  }
}

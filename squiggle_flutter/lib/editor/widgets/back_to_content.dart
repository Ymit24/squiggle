import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class BackToContent extends StatelessWidget {
  const BackToContent({super.key, required this.editorContext});

  final EditorContext editorContext;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editorContext,
      builder: (context, _) {
        final nodesOnScreen = editorContext.camera.getNodesInViewport(
          editorContext.document,
        );
        if (nodesOnScreen.isNotEmpty) {
          return SizedBox.shrink();
        }
        final theme = context.squiggleTheme;
        return Positioned(
          left: 0,
          right: 0,
          bottom: theme.spacing.overlayTop,
          child: Center(
            child: TextButton.icon(
              onPressed: () {
                print("CLICK");
              },
              icon: Icon(
                Icons.center_focus_strong_rounded,
                size: 16,
                color: theme.colors.subtext0,
              ),
              label: Text(
                'Back to content',
                style: theme.typography.panelButtonLabel(isPrimary: false),
              ),
              style: TextButton.styleFrom(
                backgroundColor: theme.colors.mantle,
                foregroundColor: theme.colors.text,
                side: BorderSide(color: theme.colors.surface1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    theme.radii.floatingPanel,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class BackToContent extends StatefulWidget {
  const BackToContent({super.key, required this.editorContext});

  final EditorContext editorContext;

  @override
  State<BackToContent> createState() => _BackToContentState();
}

class _BackToContentState extends State<BackToContent> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.editorContext,
      builder: (context, _) {
        final nodesOnScreen = widget.editorContext.camera.getNodesInViewport(
          widget.editorContext.document,
        );

        if (nodesOnScreen.isNotEmpty ||
            widget.editorContext.document.nodes.isEmpty) {
          return SizedBox.shrink();
        }

        final theme = context.squiggleTheme;
        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onJumpBackToContent,
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: theme.decorations.floatingPanel().copyWith(
                color: _hovering
                    ? theme.colors.surface0.withValues(alpha: 0.85)
                    : theme.colors.mantle,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong_rounded,
                      size: 16,
                      color: theme.colors.subtext0,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back to content',
                      style: theme.typography.panelButtonLabel(
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TODO: Write tests for this code.
  void onJumpBackToContent() {
    final cameraOrigin = widget.editorContext.camera.location;
    final nodes = widget.editorContext.document.nodes;

    var closest = (
      nodes.first,
      (nodes.first.origin - cameraOrigin).distanceSquared,
    );

    for (final node in nodes) {
      final distanceSquared = (node.origin - cameraOrigin).distanceSquared;
      if (distanceSquared < closest.$2) {
        closest = (node, distanceSquared);
      }
    }

    // TODO: Need a way to cancel fling when jumping camera programmatically like this.
    widget.editorContext.camera.location = closest.$1.globalOrigin;
    widget.editorContext.camera.panByScreenDelta(
      Offset(
        widget.editorContext.camera.screenSize.width / 2,
        widget.editorContext.camera.screenSize.height / 2,
      ),
    );
    widget.editorContext.notifyViewportChanged();
  }
}

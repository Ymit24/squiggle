import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void jumpBackToContent(EditorContext context) {
  final nodes = context.document.nodes;
  if (nodes.isEmpty || context.viewportSize == Size.zero) return;

  final cameraOrigin = context.camera.location;
  var closest = nodes.first;
  var closestDistance = (closest.origin - cameraOrigin).distanceSquared;
  for (final node in nodes.skip(1)) {
    final distance = (node.origin - cameraOrigin).distanceSquared;
    if (distance < closestDistance) {
      closest = node;
      closestDistance = distance;
    }
  }

  context.cancelViewportMotion();
  context.camera.location = closest.globalOrigin;
  context.camera.panByScreenDelta(context.viewportSize.center(Offset.zero));
  context.notifyViewportChanged();
}

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
          widget.editorContext.viewportSize,
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
            onTap: () => jumpBackToContent(widget.editorContext),
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
}

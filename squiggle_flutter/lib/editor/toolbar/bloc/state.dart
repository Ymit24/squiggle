enum ActiveToolKind { select, createRect, createCircle, createLine }

class ToolbarState {
  const ToolbarState({required this.activeTool});

  final ActiveToolKind activeTool;
}

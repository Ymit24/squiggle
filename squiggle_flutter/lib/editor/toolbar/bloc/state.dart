enum ActiveToolKind { select, createRect, createCircle }

class ToolbarState {
  const ToolbarState({required this.activeTool});

  final ActiveToolKind activeTool;
}

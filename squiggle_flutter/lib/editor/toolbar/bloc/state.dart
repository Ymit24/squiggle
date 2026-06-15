enum ActiveToolKind { select, createRect, createCircle, createLine, createText }

class ToolbarState {
  const ToolbarState({required this.activeTool});

  final ActiveToolKind activeTool;
}

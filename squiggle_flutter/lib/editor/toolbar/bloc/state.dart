enum ActiveToolKind { select }

class ToolbarState {
  const ToolbarState({required this.activeTool});

  final ActiveToolKind activeTool;
}

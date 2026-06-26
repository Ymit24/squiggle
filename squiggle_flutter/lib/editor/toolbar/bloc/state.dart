enum ActiveToolKind { select, createRect, createCircle, createLine, createText }

class ToolbarState {
  const ToolbarState({
    required this.activeTool,
    this.canUndo = false,
    this.canRedo = false,
  });

  final ActiveToolKind activeTool;
  final bool canUndo;
  final bool canRedo;

  ToolbarState copyWith({
    ActiveToolKind? activeTool,
    bool? canUndo,
    bool? canRedo,
  }) {
    return ToolbarState(
      activeTool: activeTool ?? this.activeTool,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

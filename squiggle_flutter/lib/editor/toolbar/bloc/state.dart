class ToolbarState {
  const ToolbarState({this.canUndo = false, this.canRedo = false});

  final bool canUndo;
  final bool canRedo;

  ToolbarState copyWith({bool? canUndo, bool? canRedo}) {
    return ToolbarState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

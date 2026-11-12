enum SelectionResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  bool get isCorner => switch (this) {
    topLeft || topRight || bottomLeft || bottomRight => true,
    _ => false,
  };

  bool get movesLeft => this == topLeft || this == left || this == bottomLeft;

  bool get movesRight =>
      this == topRight || this == right || this == bottomRight;

  bool get movesTop => this == topLeft || this == top || this == topRight;

  bool get movesBottom =>
      this == bottomLeft || this == bottom || this == bottomRight;
}

/// How a text feature's box is derived from its contents.
enum TextSizing {
  /// Width and height both follow the contents; lines never wrap.
  auto,

  /// Width is set by the user and lines wrap at it; height follows the contents.
  fixedWidth,
}

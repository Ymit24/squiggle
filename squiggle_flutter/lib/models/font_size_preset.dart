enum FontSizePreset {
  small(16),
  medium(24),
  large(36);

  const FontSizePreset(this.size);

  final double size;

  static const FontSizePreset defaultPreset = FontSizePreset.medium;

  static FontSizePreset? fromSize(double size) {
    for (final preset in FontSizePreset.values) {
      if (preset.size == size) {
        return preset;
      }
    }
    return null;
  }
}

/// Default canvas font size for new text features.
///
/// Must match [FontSizePreset.defaultPreset.size].
const defaultFontSize = 24.0;

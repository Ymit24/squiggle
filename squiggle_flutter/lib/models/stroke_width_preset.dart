enum StrokeWidthPreset {
  thin(3.0),
  medium(8.0),
  thick(16.0);

  const StrokeWidthPreset(this.width);

  final double width;

  static const StrokeWidthPreset defaultPreset = StrokeWidthPreset.medium;

  static StrokeWidthPreset? fromWidth(double width) {
    for (final preset in StrokeWidthPreset.values) {
      if (preset.width == width) {
        return preset;
      }
    }
    return null;
  }
}

/// Default canvas stroke width for new features.
///
/// Must match [StrokeWidthPreset.defaultPreset.width].
const defaultStrokeWidth = 8.0;

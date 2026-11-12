//! Stroke width presets (`stroke_width_preset.dart`).

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StrokeWidthPreset {
    Thin,
    Medium,
    Thick,
}

/// Default canvas stroke width for new features; equals `StrokeWidthPreset::DEFAULT.width()`.
pub const DEFAULT_STROKE_WIDTH: f64 = 8.0;

impl StrokeWidthPreset {
    pub const ALL: [StrokeWidthPreset; 3] = [Self::Thin, Self::Medium, Self::Thick];
    pub const DEFAULT: StrokeWidthPreset = Self::Medium;

    pub fn width(self) -> f64 {
        match self {
            Self::Thin => 3.0,
            Self::Medium => 8.0,
            Self::Thick => 16.0,
        }
    }

    pub fn from_width(width: f64) -> Option<Self> {
        Self::ALL.into_iter().find(|p| p.width() == width)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_stroke_width_matches_default_preset() {
        assert_eq!(DEFAULT_STROKE_WIDTH, StrokeWidthPreset::DEFAULT.width());
    }

    #[test]
    fn from_width_finds_presets() {
        assert_eq!(StrokeWidthPreset::from_width(16.0), Some(StrokeWidthPreset::Thick));
        assert_eq!(StrokeWidthPreset::from_width(5.0), None);
    }
}

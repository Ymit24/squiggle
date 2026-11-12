//! Font size presets (`font_size_preset.dart`).

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FontSizePreset {
    Small,
    Medium,
    Large,
}

/// Default canvas font size for new text features; equals `FontSizePreset::DEFAULT.size()`.
pub const DEFAULT_FONT_SIZE: f64 = 24.0;

impl FontSizePreset {
    pub const ALL: [FontSizePreset; 3] = [Self::Small, Self::Medium, Self::Large];
    pub const DEFAULT: FontSizePreset = Self::Medium;

    pub fn size(self) -> f64 {
        match self {
            Self::Small => 16.0,
            Self::Medium => 24.0,
            Self::Large => 36.0,
        }
    }

    pub fn from_size(size: f64) -> Option<Self> {
        Self::ALL.into_iter().find(|p| p.size() == size)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_font_size_matches_default_preset() {
        assert_eq!(DEFAULT_FONT_SIZE, FontSizePreset::DEFAULT.size());
    }
}

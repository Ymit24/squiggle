//! Default colours for new canvas features (document content, not UI chrome) and the few UI
//! colours that kinds paint with (`document_colors.dart`, `squiggle_color_scheme.dart`).

use crate::color::Color;

pub const DEFAULT_FEATURE_STROKE_COLOR: Color = Color(0xFFFF_FFFF);
pub const DEFAULT_FEATURE_FILL_COLOR: Color = Color(0xFF00_0000);
pub const TRANSPARENT_FILL_COLOR: Color = Color(0x0000_0000);
pub const TRANSPARENT_STROKE_COLOR: Color = Color(0x0000_0000);
pub const DEFAULT_NEW_TEXT_FILL_COLOR: Color = DEFAULT_FEATURE_STROKE_COLOR;

/// Stroke/fill colour pair offered in the style panel.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct StylePreset {
    pub stroke_color: Color,
    pub fill_color: Color,
}

const fn preset(stroke: u32, fill: u32) -> StylePreset {
    StylePreset { stroke_color: Color(stroke), fill_color: Color(fill) }
}

/// Muted studio palette: strokes are deeper, fills are soft tints within each hue.
pub const STYLE_PRESETS: [StylePreset; 11] = [
    preset(0x0000_0000, 0x0000_0000),
    preset(0xFFC4_597A, 0xFFE8_B8C8),
    preset(0xFF4A_72B8, 0xFFB0_C8E8),
    preset(0xFF3D_8C62, 0xFFA8_D8BC),
    preset(0xFFB8_883A, 0xFFE8_D4A0),
    preset(0xFF7A_62A8, 0xFFC8_B8E0),
    preset(0xFFBC_7248, 0xFFE8_C8A8),
    preset(0xFF38_98A0, 0xFFA0_D8E0),
    preset(0xFF6A_7490, 0xFFB8_C0D4),
    preset(0xFFDC_E0EC, 0xFFEA_ECF4),
    preset(0xFF2E_3244, 0xFF5C_6278),
];

pub fn stroke_preset_index_for_color(color: Color) -> Option<usize> {
    STYLE_PRESETS.iter().position(|p| p.stroke_color == color)
}

pub fn fill_preset_index_for_color(color: Color) -> Option<usize> {
    STYLE_PRESETS.iter().position(|p| p.fill_color == color)
}

/// Label text colour on rectangles and circles.
pub const LABEL_COLOR: Color = Color::WHITE;

/// UI theme colours (`SquiggleColors`) that the document model paints with.
pub mod squiggle_colors {
    use crate::color::Color;
    pub const BASE: Color = Color(0xFF17_1717);
    pub const MANTLE: Color = Color(0xFF11_1111);
    pub const SURFACE0: Color = Color(0xFF24_2424);
    pub const SURFACE1: Color = Color(0xFF36_3636);
    pub const SUBTEXT0: Color = Color(0xFFA0_A0A0);
    pub const TEXT: Color = Color(0xFFE4_E4E4);
    pub const ACCENT: Color = Color(0xFFA8_B3C2);
    pub const SELECTION_FILL: Color = Color(0x1AA8_B3C2);
    pub const DANGER: Color = Color(0xFFF2_8B8B);
    pub const ON_DANGER: Color = Color(0xFFD9_5F5F);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preset_lookup() {
        assert_eq!(stroke_preset_index_for_color(Color(0xFF4A_72B8)), Some(2));
        assert_eq!(fill_preset_index_for_color(Color(0xFF5C_6278)), Some(10));
        assert_eq!(stroke_preset_index_for_color(Color(0xFF12_3456)), None);
    }
}

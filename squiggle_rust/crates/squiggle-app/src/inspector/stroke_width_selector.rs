//! Stroke width presets (port of `stroke_width_selector.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use super::icons::width_bar;
use crate::state::State;
use rune::El;
use squiggle_core::stroke_width::StrokeWidthPreset;

/// Bar height in the picker (not the canvas stroke width).
fn preview_bar_height(preset: StrokeWidthPreset) -> f32 {
    match preset {
        StrokeWidthPreset::Thin => 2.0,
        StrokeWidthPreset::Medium => 5.0,
        StrokeWidthPreset::Thick => 9.0,
    }
}

fn tooltip(preset: StrokeWidthPreset) -> &'static str {
    match preset {
        StrokeWidthPreset::Thin => "Thin",
        StrokeWidthPreset::Medium => "Medium",
        StrokeWidthPreset::Thick => "Thick",
    }
}

pub fn stroke_width_selector(
    key: &str,
    active: Option<StrokeWidthPreset>,
    mixed: bool,
    on_select: impl Fn(&mut State, StrokeWidthPreset) + 'static,
) -> El {
    choice_row(key, &StrokeWidthPreset::ALL, Choice::new(active, mixed, on_select), tooltip, |preset, active| {
        width_bar(preview_bar_height(preset), glyph_color(active))
    })
}

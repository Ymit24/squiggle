//! Font size presets (port of `font_size_selector.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use super::style_swatch::centered;
use crate::state::State;
use rune::tok::TextStyle;
use rune::{El, text};
use squiggle_core::font_size_preset::FontSizePreset;

/// Label size in the picker (not the canvas font size).
fn preview_font_size(preset: FontSizePreset) -> f32 {
    match preset {
        FontSizePreset::Small => 8.0,
        FontSizePreset::Medium => 11.0,
        FontSizePreset::Large => 15.0,
    }
}

fn tooltip(preset: FontSizePreset) -> &'static str {
    match preset {
        FontSizePreset::Small => "Small",
        FontSizePreset::Medium => "Medium",
        FontSizePreset::Large => "Large",
    }
}

pub fn font_size_selector(
    key: &str,
    active: Option<FontSizePreset>,
    mixed: bool,
    on_select: impl Fn(&mut State, FontSizePreset) + 'static,
) -> El {
    choice_row(key, &FontSizePreset::ALL, Choice::new(active, mixed, on_select), tooltip, |preset, active| {
        centered(text("aA").font(TextStyle::new(preview_font_size(preset), 600.0)).color(glyph_color(active)))
    })
}

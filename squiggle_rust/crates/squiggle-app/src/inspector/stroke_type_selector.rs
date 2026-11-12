//! Solid / dashed / dotted strokes (port of `stroke_type_selector.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use super::icons::stroke_type_preview;
use crate::state::State;
use rune::El;
use squiggle_core::stroke_type::StrokeType;

fn tooltip(stroke_type: StrokeType) -> &'static str {
    match stroke_type {
        StrokeType::Solid => "Solid",
        StrokeType::Dashed => "Dashed",
        StrokeType::Dotted => "Dotted",
    }
}

pub fn stroke_type_selector(
    key: &str,
    active: Option<StrokeType>,
    mixed: bool,
    enabled: bool,
    on_select: impl Fn(&mut State, StrokeType) + 'static,
) -> El {
    let choice = Choice::new(active, mixed, on_select).enabled(enabled);
    choice_row(key, StrokeType::ALL, choice, tooltip, |t, active| stroke_type_preview(t, glyph_color(active)))
}

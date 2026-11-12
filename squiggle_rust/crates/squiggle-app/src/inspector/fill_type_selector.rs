//! Solid / lines / crosshatch fills (port of `fill_type_selector.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use super::icons::fill_type_preview;
use crate::state::State;
use rune::El;
use squiggle_core::fill_type::FillType;

fn tooltip(fill_type: FillType) -> &'static str {
    match fill_type {
        FillType::Solid => "Solid",
        FillType::Lines => "Lines",
        FillType::Crosshatch => "Crosshatch",
    }
}

pub fn fill_type_selector(
    key: &str,
    active: Option<FillType>,
    mixed: bool,
    enabled: bool,
    on_select: impl Fn(&mut State, FillType) + 'static,
) -> El {
    let choice = Choice::new(active, mixed, on_select).enabled(enabled);
    choice_row(key, FillType::ALL, choice, tooltip, |t, active| fill_type_preview(t, glyph_color(active)))
}

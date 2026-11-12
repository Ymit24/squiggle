//! Line end caps, for either end of a polyline (port of `line_end_cap_selector.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use super::icons::end_cap;
use crate::state::State;
use rune::El;
use squiggle_core::line_end_cap::LineEndCap;

fn tooltip(cap: LineEndCap) -> &'static str {
    match cap {
        LineEndCap::Rounded => "Rounded",
        LineEndCap::Arrow => "Arrow",
    }
}

pub fn line_end_cap_selector(
    key: &str,
    active: Option<LineEndCap>,
    mixed: bool,
    is_start: bool,
    on_select: impl Fn(&mut State, LineEndCap) + 'static,
) -> El {
    choice_row(key, LineEndCap::ALL, Choice::new(active, mixed, on_select), tooltip, |cap, active| {
        end_cap(cap == LineEndCap::Arrow, is_start, glyph_color(active))
    })
}

//! Swatch row of alignment icons (port of `alignment_swatch.dart`).

use super::choice_row::{Choice, choice_row, glyph_color};
use crate::state::State;
use rune::{Color, El};

/// A row of alignment swatches; `icon` draws the glyph of one alignment in a colour.
#[allow(clippy::too_many_arguments)]
pub fn alignment_row<T: Copy + PartialEq + 'static>(
    key: &str,
    values: &[T],
    active: Option<T>,
    mixed: bool,
    enabled: bool,
    on_select: impl Fn(&mut State, T) + 'static,
    tooltip: fn(T) -> &'static str,
    icon: fn(T, Color) -> El,
) -> El {
    let choice = Choice::new(active, mixed, on_select).enabled(enabled);
    choice_row(key, values, choice, tooltip, move |value, active| icon(value, glyph_color(active)))
}

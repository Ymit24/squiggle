//! Top / centre / bottom text alignment (port of `text_vertical_alignment_selector.dart`).

use super::alignment_swatch::alignment_row;
use super::icons::text_align_vertical;
use crate::state::State;
use rune::El;
use squiggle_core::text_alignment::TextVerticalAlignment;

fn tooltip(alignment: TextVerticalAlignment) -> &'static str {
    match alignment {
        TextVerticalAlignment::Top => "Align top",
        TextVerticalAlignment::Center => "Align middle",
        TextVerticalAlignment::Bottom => "Align bottom",
    }
}

pub fn text_vertical_alignment_selector(
    key: &str,
    active: Option<TextVerticalAlignment>,
    mixed: bool,
    enabled: bool,
    on_select: impl Fn(&mut State, TextVerticalAlignment) + 'static,
) -> El {
    alignment_row(key, TextVerticalAlignment::ALL, active, mixed, enabled, on_select, tooltip, text_align_vertical)
}

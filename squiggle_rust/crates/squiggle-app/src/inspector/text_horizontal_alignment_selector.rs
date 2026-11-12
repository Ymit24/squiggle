//! Left / centre / right text alignment (port of `text_horizontal_alignment_selector.dart`).

use super::alignment_swatch::alignment_row;
use super::icons::text_align_horizontal;
use crate::state::State;
use rune::El;
use squiggle_core::text_alignment::TextHorizontalAlignment;

fn tooltip(alignment: TextHorizontalAlignment) -> &'static str {
    match alignment {
        TextHorizontalAlignment::Left => "Align left",
        TextHorizontalAlignment::Center => "Align center",
        TextHorizontalAlignment::Right => "Align right",
    }
}

pub fn text_horizontal_alignment_selector(
    key: &str,
    active: Option<TextHorizontalAlignment>,
    mixed: bool,
    enabled: bool,
    on_select: impl Fn(&mut State, TextHorizontalAlignment) + 'static,
) -> El {
    alignment_row(key, TextHorizontalAlignment::ALL, active, mixed, enabled, on_select, tooltip, text_align_horizontal)
}

//! Small button that clears a brush override (port of `brush_field_reset_button.dart`).

use crate::kit::LABEL;
use crate::state::State;
use crate::theme;
use rune::{El, row, text};

pub fn brush_field_reset_button(key: &str, on_press: impl Fn(&mut State) + 'static) -> El {
    row()
        .key(format!("reset-{key}"))
        .size(20.0, 20.0)
        .items_center()
        .justify_center()
        .radius(4.0)
        .help("Clear brush override")
        .label("Clear brush override")
        .hover(theme::surface1()).motion(rune::tok::motion::SNAPPY)
        .on_press(on_press)
        .child(text("\u{21BA}").font(LABEL).color(theme::subtext()))
}

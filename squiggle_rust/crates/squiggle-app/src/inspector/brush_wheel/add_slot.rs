//! The wheel's trailing "new brush" slot (port of `brush_wheel_add_slot.dart`).

use super::tile::brush_wheel_tile;
use crate::theme;
use rune::tok::TextStyle;
use rune::{El, text};

pub fn brush_wheel_add_slot(hovered: bool) -> El {
    let plus = text("+").font(TextStyle::new(22.0, 400.0)).color(if hovered { theme::text() } else { theme::subtext() });
    brush_wheel_tile(hovered, false, plus).key("brush-wheel-add")
}

//! The shared frame of a wheel slot: a tile that grows and highlights while hovered, with an
//! accent border when active (port of `brush_wheel_tile.dart`).

use crate::kit::metrics::FLOATING_PANEL_RADIUS;
use crate::theme;
use rune::{El, row};
use squiggle_core::brush_wheel_geometry::{HOVER_SCALE, SLOT_SIZE};

pub fn brush_wheel_tile(hovered: bool, active: bool, child: El) -> El {
    let border = if hovered {
        theme::text()
    } else if active {
        theme::accent()
    } else {
        theme::surface1()
    };
    row()
        .size(SLOT_SIZE as f32, SLOT_SIZE as f32)
        .items_center()
        .justify_center()
        .radius(FLOATING_PANEL_RADIUS)
        .fill(if hovered { theme::surface0() } else { theme::base() })
        .border(1.0, border)
        .scale(if hovered { HOVER_SCALE as f32 } else { 1.0 })
        .child(child)
}

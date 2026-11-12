//! One brush in the dropdown: name, check, shortcut hint and preview (port of
//! `brush_menu_entry.dart`).

use super::brush_sample::brush_preview;
use super::metrics::{BRUSH_ENTRY_HEIGHT, BRUSH_ENTRY_VERTICAL_PADDING, BRUSH_PREVIEW_GAP};
use crate::kit::{BODY, LABEL, metrics};
use crate::theme;
use rune::{El, col, row, text};
use squiggle_core::session::BrushProfile;

/// Keyed by the brush id. The caller adds the press or drag behaviour.
pub fn brush_menu_entry(brush: &BrushProfile, selected: bool, shortcut_number: Option<usize>) -> El {
    let mut title = row().w_full().items_center().gap(6.0).child(text(brush.name.clone()).font(BODY).color(theme::text()).truncate().grow(1.0));
    if selected {
        title = title.child(text("\u{2713}").font(LABEL).color(theme::text()));
    }
    if let Some(n) = shortcut_number {
        title = title.child(text(format!("\u{2318}{n}")).font(LABEL).color(theme::subtext()));
    }
    col()
        .key(brush.id.clone())
        .w_full()
        .h(BRUSH_ENTRY_HEIGHT)
        .px(metrics::MENU_PADDING)
        .py(BRUSH_ENTRY_VERTICAL_PADDING)
        .gap(BRUSH_PREVIEW_GAP)
        .radius(metrics::BUTTON_RADIUS)
        .fill(if selected { theme::surface0() } else { rune::Color::TRANSPARENT })
        .hover(theme::surface1()).motion(rune::tok::motion::SNAPPY)
        .child(title)
        .child(brush_preview(&brush.values))
}

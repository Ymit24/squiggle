//! The brush list: Scratch and Create stay fixed while named profiles can be reordered (port of
//! `brush_dropdown.dart`). It opens inline under the picker button.

use super::brush_menu_entry::brush_menu_entry;
use super::brush_name_dialog::open_create;
use super::brush_ops;
use super::brush_reorder_row::brush_reorder_row;
use super::metrics::{BRUSH_ENTRY_HEIGHT, PANEL_INNER_WIDTH};
use crate::kit::{self, metrics};
use crate::state::State;
use rune::{El, ScrollSpec, col};

fn display_order(named: &[&squiggle_core::session::BrushProfile], reorder: Option<&super::Reorder>) -> Vec<usize> {
    let mut order: Vec<usize> = (0..named.len()).collect();
    if let Some(r) = reorder.filter(|r| r.from < order.len()) {
        let item = order.remove(r.from);
        order.insert(r.target.min(order.len()), item);
    }
    order
}

/// `max_height` bounds the profile list, which scrolls when taller.
pub fn brush_dropdown(s: &State, max_height: f32) -> El {
    let session = &s.ctx.document.session;
    let active = &session.active_brush().id;
    let scratch = &session.brushes[0];
    let named: Vec<_> = session.brushes.iter().skip(1).collect();
    let reorder = s.inspector_ui.reorder.as_ref();

    let scratch_entry = brush_menu_entry(scratch, &scratch.id == active, Some(1)).on_press(|s: &mut State| {
        brush_ops::activate(&mut s.ctx, "scratch");
        s.inspector_ui.picker_open = false;
        s.autosave_if_changed();
    });
    let rows = display_order(&named, reorder).into_iter().enumerate().map(|(place, original)| {
        let brush = named[original];
        let dragging = reorder.is_some_and(|r| r.id == brush.id);
        brush_reorder_row(brush, place, &brush.id == active, dragging)
    });
    let list = col().key("brush-reorder-list").w_full().children(rows);
    let list_height = (named.len() as f32 * BRUSH_ENTRY_HEIGHT).min(max_height);
    let list = col().w_full().h(list_height).min_h(0.0).scroll(ScrollSpec { stick_bottom: false }).child(list);

    let can_create = session.can_create_brush();
    let create = kit::menu_item("brush-create", "Create brush", None, can_create, |s: &mut State| open_create(s));
    col()
        .key("brush-dropdown")
        .w(PANEL_INNER_WIDTH)
        .padding(0.0)
        .child(scratch_entry)
        .child(list)
        .child(kit::divider_horizontal())
        .child(create.h(metrics::MENU_ITEM_HEIGHT))
}

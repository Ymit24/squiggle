//! "Brush" row: the active brush's dropdown trigger and its management menu (port of
//! `brush_picker.dart`). The dropdown and the menu open inline and exclude each other.

use super::brush_dropdown::brush_dropdown;
use super::brush_name_dialog::open_rename;
use super::delete_brush_dialog::open_delete;
use crate::kit::{self, BODY, metrics};
use crate::state::State;
use crate::theme;
use rune::{El, col, row, text};

fn trigger(key: &str, grow: bool, content: El, on_press: fn(&mut State)) -> El {
    let button = row()
        .key(key.to_owned())
        .h(32.0)
        .px(6.0)
        .items_center()
        .gap(4.0)
        .radius(metrics::BUTTON_RADIUS)
        .border(1.0, theme::surface1())
        .fill(theme::surface0())
        .hover(theme::surface1()).motion(rune::tok::motion::SNAPPY)
        .focusable(true)
        .on_press(on_press)
        .child(content);
    if grow { button.grow(1.0).min_w(0.0) } else { button.w(28.0).justify_center() }
}

fn toggle_picker(s: &mut State) {
    let ui = &mut s.inspector_ui;
    ui.actions_open = false;
    ui.picker_open = !ui.picker_open;
}

fn toggle_actions(s: &mut State) {
    let ui = &mut s.inspector_ui;
    ui.picker_open = false;
    ui.actions_open = !ui.actions_open;
}

fn actions_menu() -> El {
    col()
        .key("brush-actions-menu")
        .w_full()
        .child(kit::menu_item("brush-rename", "Rename\u{2026}", None, true, |s: &mut State| open_rename(s)))
        .child(kit::menu_item("brush-delete", "Delete brush", None, true, |s: &mut State| open_delete(s)))
}

/// `list_height` is the room the dropdown's profile list may take.
pub fn brush_picker(s: &State, list_height: f32) -> El {
    let brush = s.ctx.document.session.active_brush();
    let ui = &s.inspector_ui;
    let name = row()
        .grow(1.0)
        .min_w(0.0)
        .child(text(brush.name.clone()).font(BODY).color(theme::text()).truncate())
        .child(rune::spacer())
        .child(text("\u{25BE}").font(BODY).color(theme::subtext()));
    let mut controls = row().w_full().gap(4.0).child(trigger("brush-picker-trigger", true, name, toggle_picker));
    if !brush.is_scratch() {
        let more = text("\u{22EF}").font(BODY).color(theme::text());
        controls = controls.child(trigger("brush-actions-trigger", false, more, toggle_actions).help("Manage active brush"));
    }
    let mut picker = col().gap(4.0).child(text("Brush").font(BODY).color(theme::text())).child(controls);
    if ui.picker_open {
        picker = picker.child(brush_dropdown(s, list_height));
    }
    if ui.actions_open && !brush.is_scratch() {
        picker = picker.child(actions_menu());
    }
    picker
}

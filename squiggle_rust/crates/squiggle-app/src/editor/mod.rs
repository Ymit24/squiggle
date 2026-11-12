//! Editor page: viewport, toolbar, shortcuts, context menu, inline text editing.
//! Owner: editor-chrome. `view` is called by `main.rs` when `Page::Editor` is active.

pub mod command;
pub mod context_menu;
pub mod shortcuts;
pub mod text_overlay;
pub mod toolbar;

use crate::state::State;
use rune::{Cx, El, el};
use squiggle_core::geom::Point;
use squiggle_core::tools::tool::Modifiers;

/// Transient editor-page UI state.
#[derive(Default)]
pub struct EditorUi {
    /// Modifier keys currently held (from `App::on_modifiers`).
    pub mods: Modifiers,
    /// Last pointer position over the viewport, in viewport pixels.
    pub pointer: Point,
    /// Camera location when a pan drag (secondary/middle button) began.
    pub pan_origin: Option<Point>,
    /// Open context menu: (viewport position, world position).
    pub context_menu: Option<(Point, Point)>,
    /// The inline text field's content and the core session it was made for.
    pub text: rune::TextEdit,
    /// Whether the freshly opened field has been focused yet.
    pub text_focus_done: bool,
    pub text_session: Option<squiggle_core::editor::text_edit::TextEditSession>,
}

pub fn view(s: &State, _cx: &mut Cx<State>) -> El {
    el()
        .w_full()
        .h_full()
        .on_key_up(|s: &mut State, e: &rune::KeyEvent, _tx| {
            let released_b = e.key == rune::Key::Text("b".into());
            if released_b && crate::inspector::brush_wheel::host::is_open(s) {
                crate::inspector::brush_wheel::host::close(s, true);
            }
            released_b
        })
        .child(crate::viewport::view(s))
        .child(text_overlay::view(s))
        .child(toolbar::view(s))
        .child(crate::inspector::panel(s))
        .child(back_to_content(s))
        .child(context_menu::view(s))
        .child(crate::inspector::overlays(s))
}

/// Window-level key handler: tool/edit shortcuts (installed via `AppSpec::on_key`).
pub fn on_key(s: &mut State, e: &rune::KeyEvent, tx: &mut rune::Tx) -> bool {
    if s.page != crate::state::Page::Editor {
        return false;
    }
    use crate::inspector::{brush_wheel::host, close_menus};
    if host::is_open(s) {
        // The wheel is modal while B is held.
        if e.key == rune::Key::Escape {
            host::close(s, false);
        }
        return true;
    }
    if e.key == rune::Key::Text("b".into()) && !e.mods.cmd && !e.mods.ctrl {
        let held = e.mods.shift || e.mods.alt;
        if host::open(s, held) {
            return true;
        }
    }
    if e.key == rune::Key::Escape && close_menus(s) {
        return true;
    }
    match shortcuts::command_for(e) {
        Some(cmd) => {
            command::run(s, tx, cmd);
            true
        }
        None => false,
    }
}

fn back_to_content(s: &State) -> El {
    if !s.ctx.content_is_off_screen() {
        return el();
    }
    rune::row().absolute(0.0, 0.0).w_full().h_full().justify_center().items_end().padding(24.0).child(
        crate::kit::button("Back to content", |s: &mut State| s.ctx.jump_back_to_content()).key("back-to-content"),
    )
}

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
        .child(crate::viewport::view(s))
        .child(text_overlay::view(s))
        .child(toolbar::view(s))
        .child(crate::inspector::panel(s))
        .child(context_menu::view(s))
}

/// Window-level key handler: tool/edit shortcuts (installed via `AppSpec::on_key`).
pub fn on_key(s: &mut State, e: &rune::KeyEvent, tx: &mut rune::Tx) -> bool {
    if s.page != crate::state::Page::Editor {
        return false;
    }
    match shortcuts::command_for(e) {
        Some(cmd) => {
            command::run(s, tx, cmd);
            true
        }
        None => false,
    }
}

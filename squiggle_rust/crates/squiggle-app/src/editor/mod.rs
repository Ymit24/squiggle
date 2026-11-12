//! Editor page: viewport, toolbar, shortcuts, context menu, inline text editing.
//! Owner: editor-chrome. `view` is called by `main.rs` when `Page::Editor` is active.

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
}

pub fn view(s: &State, _cx: &mut Cx<State>) -> El {
    el().w_full().h_full().child(crate::viewport::view(s))
}

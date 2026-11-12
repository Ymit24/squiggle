//! Editor page: viewport, toolbar, shortcuts, context menu, inline text editing.
//! Owner: editor-chrome agent. `view` is called by `main.rs` when `Page::Editor` is active.

use crate::state::State;
use rune::{Cx, El};

#[derive(Default)]
pub struct EditorUi {}

pub fn view(s: &State, _cx: &mut Cx<State>) -> El {
    crate::viewport::view(s)
}

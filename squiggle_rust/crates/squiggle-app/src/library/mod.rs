//! Document library page. Owner: library agent. `view` is shown when `Page::Library` is active.

use crate::state::State;
use rune::{Cx, El, col};

#[derive(Default)]
pub struct LibraryUi {}

pub fn view(_s: &State, _cx: &mut Cx<State>) -> El {
    col()
}

//! Inspector panel, brush picker and brush wheel. Owner: inspector agent.
//! `panel` returns the floating inspector overlay (or an empty element when nothing to show).

use crate::state::State;
use rune::{El, el};

#[derive(Default)]
pub struct InspectorUi {}

pub fn panel(_s: &State) -> El {
    el()
}

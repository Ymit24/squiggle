//! Pressed on empty canvas: a drag becomes a marquee, a release clears the selection
//! (`click_canvas_state.dart`).

use super::box_selection_state::BoxSelectionState;
use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use crate::geom::Point;

pub struct ClickCanvasState {
    start: Point,
}

impl ClickCanvasState {
    pub fn new(start: Point) -> Self {
        ClickCanvasState { start }
    }
}

impl InteractionState for ClickCanvasState {
    fn on_pointer_move(&mut self, _cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        Transition::forward(BoxSelectionState::new(self.start, ev.shift()))
    }

    fn on_pointer_up(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        if !ev.shift() {
            cx.ctx.selection.set_selection([]);
        }
        Transition::to(IdleInteractionState)
    }
}

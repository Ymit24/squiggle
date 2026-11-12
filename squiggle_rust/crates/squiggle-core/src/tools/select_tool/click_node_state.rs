//! Pressed on a node: a drag moves (or, with Alt, duplicates) the selection, a release selects
//! (`click_node_state.dart`).

use super::duplicate_state::DuplicateState;
use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::translate_state::TranslateState;
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::tools::tool::EditorCursor;

pub struct ClickNodeState {
    start: Point,
    chase: NodeId,
    selected: Vec<NodeId>,
    is_shift: bool,
    was_selected: bool,
}

impl ClickNodeState {
    pub fn new(start: Point, chase: NodeId, selected: Vec<NodeId>, is_shift: bool) -> Self {
        let was_selected = selected.contains(&chase);
        ClickNodeState { start, chase, selected, is_shift, was_selected }
    }
}

impl InteractionState for ClickNodeState {
    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point) -> EditorCursor {
        EditorCursor::Grabbing
    }

    fn on_enter(&mut self, cx: &mut Cx) -> bool {
        if self.was_selected {
            return true;
        }
        if self.is_shift {
            cx.ctx.selection.select_node(self.chase);
            self.selected.push(self.chase);
        } else {
            cx.ctx.selection.set_selection([self.chase]);
            self.selected = vec![self.chase];
        }
        true
    }

    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        if self.selected.is_empty() {
            return None;
        }
        let label = if ev.alt() { "Duplicate selection" } else { "Move selection" };
        cx.txn.begin(cx.ctx, label, &self.selected).ok()?;
        let selected = self.selected.clone();
        if ev.alt() {
            let origins = DuplicateState::origins_of(&cx.ctx.document, &selected);
            Transition::forward(DuplicateState::new(self.start, selected, origins, false))
        } else {
            Transition::forward(TranslateState::new(self.start, selected, &cx.ctx.document))
        }
    }

    fn on_pointer_up(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        if ev.shift() {
            if self.was_selected {
                cx.ctx.selection.deselect_node(self.chase);
            }
        } else {
            cx.ctx.selection.set_selection([self.chase]);
        }
        Transition::to(IdleInteractionState)
    }
}

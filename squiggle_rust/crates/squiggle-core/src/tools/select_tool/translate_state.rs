//! Dragging the selection (`translate_state.dart`).

use super::duplicate_state::DuplicateState;
use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use crate::document::Document;
use crate::editor::context::EditorContext;
use crate::feature_geometry::constrained_move_delta;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::tools::tool::EditorCursor;

pub struct TranslateState {
    start: Point,
    selected: Vec<NodeId>,
    initial_origins: Vec<(NodeId, Point)>,
    has_duplicated: bool,
}

impl TranslateState {
    pub fn new(start: Point, selected: Vec<NodeId>, doc: &Document) -> Self {
        let initial_origins = DuplicateState::origins_of(doc, &selected);
        TranslateState { start, selected, initial_origins, has_duplicated: false }
    }

    /// Translates `selected` (already duplicates) from the given initial origins.
    pub fn after_duplicate(start: Point, selected: Vec<NodeId>, initial_origins: Vec<(NodeId, Point)>) -> Self {
        TranslateState { start, selected, initial_origins, has_duplicated: true }
    }
}

impl InteractionState for TranslateState {
    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point) -> EditorCursor {
        EditorCursor::Grabbing
    }

    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        let motion = constrained_move_delta(self.start, ev.world, ev.shift());
        if ev.alt() && !self.has_duplicated {
            let state =
                DuplicateState::new(self.start, self.selected.clone(), self.initial_origins.clone(), true);
            return Transition::forward(state);
        }
        for &(id, origin) in &self.initial_origins {
            if let Some(node) = cx.ctx.document.node_mut(id) {
                node.set_origin(origin + motion);
            }
        }
        None
    }

    fn on_pointer_up(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        Transition::to(IdleInteractionState)
    }
}

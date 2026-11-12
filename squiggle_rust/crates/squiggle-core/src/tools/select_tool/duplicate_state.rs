//! Alt-drag: leave the originals in place and drag copies (`duplicate_state.dart`).

use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::translate_state::TranslateState;
use crate::document::Document;
use crate::feature_geometry::constrained_move_delta;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::services::duplicate_nodes::duplicate_nodes;

pub struct DuplicateState {
    start: Point,
    selected: Vec<NodeId>,
    origins_at_drag_start: Vec<(NodeId, Point)>,
    selection_already_moved: bool,
}

impl DuplicateState {
    pub fn new(
        start: Point,
        selected: Vec<NodeId>,
        origins_at_drag_start: Vec<(NodeId, Point)>,
        selection_already_moved: bool,
    ) -> Self {
        DuplicateState { start, selected, origins_at_drag_start, selection_already_moved }
    }

    pub fn origins_of(doc: &Document, ids: &[NodeId]) -> Vec<(NodeId, Point)> {
        ids.iter().filter_map(|&id| doc.node(id).map(|n| (id, n.origin()))).collect()
    }
}

impl InteractionState for DuplicateState {
    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        let motion = constrained_move_delta(self.start, ev.world, ev.shift());
        let ctx = &mut *cx.ctx;
        let tx = &mut ctx.history.edit(&mut ctx.document).ok()?;
        let clones = duplicate_nodes(&self.selected, tx, &mut ctx.selection, Point::ZERO).ok()?;

        for &(id, origin) in &self.origins_at_drag_start {
            if let Some(node) = ctx.document.node_mut(id) {
                node.set_origin(origin);
            }
        }
        let initial_origins = DuplicateState::origins_of(&ctx.document, &clones)
            .into_iter()
            .map(|(id, origin)| (id, if self.selection_already_moved { origin - motion } else { origin }))
            .collect();
        Transition::forward(TranslateState::after_duplicate(self.start, clones, initial_origins))
    }
}

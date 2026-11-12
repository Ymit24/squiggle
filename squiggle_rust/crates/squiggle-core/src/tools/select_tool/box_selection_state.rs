//! Marquee selection (`box_selection_state.dart`).

use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::selection_painter::paint_marquee;
use crate::camera::Camera;
use crate::geom::{Point, Rect};
use crate::ids::NodeId;
use crate::paint::Painter;

pub struct BoxSelectionState {
    start: Point,
    current: Point,
    is_shift: bool,
}

impl BoxSelectionState {
    pub fn new(start: Point, is_shift: bool) -> Self {
        BoxSelectionState { start, current: start, is_shift }
    }
}

impl InteractionState for BoxSelectionState {
    fn on_enter(&mut self, cx: &mut Cx) -> bool {
        if !self.is_shift {
            cx.ctx.selection.set_selection([]);
        }
        true
    }

    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        self.current = ev.world;
        let bounds = Rect::from_points(self.start, self.current);
        let ctx = &mut *cx.ctx;
        let hit: Vec<NodeId> =
            ctx.document.nodes().iter().filter(|n| n.intersects_rect(&bounds)).map(|n| n.id()).collect();
        if ev.shift() {
            hit.into_iter().for_each(|id| ctx.selection.select_node(id));
        } else {
            ctx.selection.set_selection(hit);
        }
        None
    }

    fn on_pointer_up(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        Transition::to(IdleInteractionState)
    }

    fn paint(&self, camera: &Camera, painter: &mut Painter) {
        let screen = Rect::from_points(camera.world_to_screen(self.start), camera.world_to_screen(self.current));
        paint_marquee(painter, camera.screen_to_world_bounds(screen));
    }
}

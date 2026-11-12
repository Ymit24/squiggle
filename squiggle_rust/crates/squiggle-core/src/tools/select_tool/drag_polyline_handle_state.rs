//! Dragging one vertex of the selected polyline (`drag_polyline_handle_state.dart`).

use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::polyline_handle::PolylineHandle;
use crate::editor::context::EditorContext;
use crate::feature::Feature;
use crate::feature_geometry::{snap_point_to_45_degree_angle, world_points};
use crate::feature_kind::FeatureKind;
use crate::geom::Point;
use crate::tools::tool::EditorCursor;

pub struct DragPolylineHandleState {
    handle: PolylineHandle,
}

impl DragPolylineHandleState {
    pub fn new(handle: PolylineHandle) -> Self {
        DragPolylineHandleState { handle }
    }

    fn target_position(&self, feature: &Feature, world: Point, shift: bool) -> Point {
        let FeatureKind::Polyline(polyline) = &feature.kind else { return world };
        if !shift {
            return world;
        }
        let points = world_points(feature.origin, &polyline.local_points);
        snap_point_to_45_degree_angle(self.snap_origin(&points, world), world)
    }

    fn snap_origin(&self, points: &[Point], fallback: Point) -> Point {
        let index = self.handle.point_index;
        if index > 0 {
            return points[index - 1];
        }
        points.get(1).copied().unwrap_or(fallback)
    }
}

impl InteractionState for DragPolylineHandleState {
    fn on_enter(&mut self, cx: &mut Cx) -> bool {
        cx.txn.begin(cx.ctx, "Move point", &[self.handle.feature]).is_ok()
    }

    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point) -> EditorCursor {
        EditorCursor::Grabbing
    }

    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        let feature = cx.ctx.document.feature_mut(self.handle.feature)?;
        let target = self.target_position(feature, ev.world, ev.shift());
        feature.set_polyline_point(self.handle.point_index, target);
        None
    }

    fn on_pointer_up(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        Transition::to(IdleInteractionState)
    }
}

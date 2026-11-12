//! The selection tool (`tools/select_tool/select_tool.dart`): click/marquee selection, moving and
//! alt-duplicating, resizing, polyline vertex dragging, delete and group shortcuts.
//!
//! Dart's `InteractionState` objects become boxed [`InteractionState`] trait objects owned by the
//! tool; handlers return a [`Transition`] that the tool applies.

mod box_selection_state;
mod click_canvas_state;
mod click_node_state;
mod drag_polyline_handle_state;
mod duplicate_state;
mod helpers;
mod hit_target;
mod idle_interaction_state;
mod interaction_state;
mod polyline_handle;
mod polyline_handle_util;
mod resize_handle;
mod resize_handle_util;
mod resize_policy;
mod resize_state;
mod selection_painter;
mod selection_resize_handle;
mod translate_state;

#[cfg(test)]
mod tests;

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::ids::NodeId;
use crate::paint::Painter;
use crate::tools::tool::{EditorCursor, Key, KeyInput, Modifiers, Tool, ToolId};
use idle_interaction_state::IdleInteractionState;
use interaction_state::{Cx, InteractionState, Ptr, Transition, Txn};
use std::time::Duration;

pub use helpers::{cursor_for_resize_handle, target_under_cursor};
pub use hit_target::HitTarget;
pub use polyline_handle::PolylineHandle;
pub use resize_handle::ResizeHandle;
pub use resize_handle_util::resize_handles;
pub use resize_policy::ResizePolicy;
pub use selection_painter::{paint_marquee, paint_selection, paint_selection_box, paint_vertex_handle};
pub use selection_resize_handle::SelectionResizeHandle;

pub const SELECTION_BOX_PADDING: f64 = 8.0;
pub const SELECTION_HANDLE_HIT_SIZE: f64 = 20.0;
pub const SELECTION_HANDLE_PAINT_SIZE: f64 = 12.0;
pub const DOUBLE_CLICK_INTERVAL: Duration = Duration::from_millis(300);

#[derive(Clone, Copy)]
enum PointerPhase {
    Down,
    Move,
    Up,
}

pub struct SelectTool {
    state: Box<dyn InteractionState>,
    txn: Txn,
}

impl Default for SelectTool {
    fn default() -> Self {
        SelectTool { state: Box::new(IdleInteractionState), txn: Txn::default() }
    }
}

impl SelectTool {
    fn call(
        state: &mut dyn InteractionState,
        phase: PointerPhase,
        cx: &mut Cx,
        ev: &Ptr,
    ) -> Option<Transition> {
        match phase {
            PointerPhase::Down => state.on_pointer_down(cx, ev),
            PointerPhase::Move => state.on_pointer_move(cx, ev),
            PointerPhase::Up => state.on_pointer_up(cx, ev),
        }
    }

    /// Delivers a pointer event to the active state, then applies any requested transitions. A
    /// state that fails to enter (for example when its transaction cannot start) falls back to idle.
    fn dispatch(&mut self, ctx: &mut EditorContext, phase: PointerPhase, ev: &Ptr) {
        let mut cx = Cx { ctx, txn: &mut self.txn };
        let mut pending = Self::call(self.state.as_mut(), phase, &mut cx, ev);
        while let Some(Transition { to, forward }) = pending {
            self.state = to;
            if !self.state.on_enter(&mut cx) {
                self.state = Box::new(IdleInteractionState);
                return;
            }
            pending = if forward { Self::call(self.state.as_mut(), PointerPhase::Move, &mut cx, ev) } else { None };
        }
    }

    fn pointer(&mut self, ctx: &mut EditorContext, phase: PointerPhase, world: Point, mods: Modifiers) {
        self.dispatch(ctx, phase, &Ptr { world, mods });
    }

    fn drop_missing_selection(ctx: &mut EditorContext) {
        let alive: Vec<NodeId> =
            ctx.selection.selected_node_ids().iter().copied().filter(|id| ctx.document.node(*id).is_some()).collect();
        ctx.selection.set_selection(alive);
    }
}

impl Tool for SelectTool {
    fn id(&self) -> ToolId {
        ToolId::Select
    }

    fn on_pointer_down(&mut self, ctx: &mut EditorContext, world: Point, _camera: &Camera, mods: Modifiers) -> bool {
        self.pointer(ctx, PointerPhase::Down, world, mods);
        true
    }

    fn on_pointer_move(&mut self, ctx: &mut EditorContext, world: Point, _camera: &Camera, mods: Modifiers) -> bool {
        self.pointer(ctx, PointerPhase::Move, world, mods);
        true
    }

    fn on_pointer_up(&mut self, ctx: &mut EditorContext, world: Point, _camera: &Camera, mods: Modifiers) -> bool {
        self.pointer(ctx, PointerPhase::Up, world, mods);
        self.txn.commit(ctx);
        true
    }

    fn on_double_click(&mut self, ctx: &mut EditorContext, world: Point, _camera: &Camera) -> bool {
        self.state.on_double_click(ctx, world);
        true
    }

    fn on_key(&mut self, ctx: &mut EditorContext, key: KeyInput) -> bool {
        if key.key == Key::Escape && self.state.cancels_on_escape() {
            self.cancel_interaction(ctx);
            return true;
        }
        self.state.on_key(ctx, key)
    }

    fn deactivate(&mut self, ctx: &mut EditorContext) {
        self.cancel_interaction(ctx);
        ctx.selection.clear_selection();
    }

    fn cancel_interaction(&mut self, ctx: &mut EditorContext) {
        self.state = Box::new(IdleInteractionState);
        if self.txn.cancel(ctx) {
            Self::drop_missing_selection(ctx);
        }
    }

    fn paint(&self, ctx: &EditorContext, camera: &Camera, painter: &mut Painter) {
        self.state.paint(camera, painter);
        paint_selection(ctx, camera, painter);
    }

    fn resolve_cursor(&self, ctx: &EditorContext, world: Point, _camera: &Camera) -> EditorCursor {
        self.state.resolve_cursor(ctx, world)
    }
}

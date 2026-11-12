//! Dragging a resize handle of the selected node (`resize_state.dart`).

use super::helpers::cursor_for_resize_handle;
use super::idle_interaction_state::IdleInteractionState;
use super::interaction_state::{Cx, InteractionState, Ptr, Transition};
use super::resize_handle::ResizeHandle;
use super::resize_policy::ResizePolicy;
use super::selection_resize_handle::SelectionResizeHandle as H;
use crate::document::Document;
use crate::editor::context::EditorContext;
use crate::feature_geometry::{
    ResizeEdges, edge_resize_with_aspect_ratio, rect_from_anchor_with_aspect_ratio, symmetric_rect_with_aspect_ratio,
};
use crate::geom::{Point, Rect};
use crate::node::Node;
use crate::tools::tool::EditorCursor;

pub struct ResizeState {
    handle: ResizeHandle,
    /// Pointer position relative to the grabbed handle's reference point, so a grab that is not
    /// dead-centre does not snap on the first move.
    resize_offset: Point,
    initial_bounds: Rect,
    policy: ResizePolicy,
    /// The node as it was before the drag. Every move restores it first, so a resize is always
    /// computed from the initial state and cannot compound.
    snapshot: Option<Node>,
}

impl ResizeState {
    pub fn new(handle: ResizeHandle, pointer_down_world: Point, doc: &Document) -> Option<Self> {
        let node = doc.node(handle.node)?;
        let initial_bounds = node.local_bounds();
        Some(ResizeState {
            handle,
            resize_offset: pointer_down_world - reference_for(handle.handle, &initial_bounds),
            initial_bounds,
            policy: ResizePolicy::of(node),
            snapshot: None,
        })
    }

    fn kind(&self) -> H {
        self.handle.handle
    }

    fn new_bounds(&self, world: Point, lock_aspect: bool, symmetric: bool) -> Rect {
        if symmetric {
            self.symmetric_bounds(world, lock_aspect)
        } else {
            self.asymmetric_bounds(world, lock_aspect)
        }
    }

    fn aspect_ratio(&self) -> f64 {
        self.initial_bounds.width() / self.initial_bounds.height()
    }

    fn symmetric_bounds(&self, world: Point, lock_aspect: bool) -> Rect {
        let (handle, initial) = (self.kind(), &self.initial_bounds);
        let center = initial.center();
        if lock_aspect {
            return symmetric_rect_with_aspect_ratio(
                center,
                world,
                self.aspect_ratio(),
                handle.moves_left() || handle.moves_right(),
                handle.moves_top() || handle.moves_bottom(),
            );
        }
        if handle.is_corner() {
            return Rect::from_center(center, (world.x - center.x).abs() * 2.0, (world.y - center.y).abs() * 2.0);
        }
        match handle {
            H::Top | H::Bottom => Rect::from_center(center, initial.width(), (world.y - center.y).abs() * 2.0),
            _ => Rect::from_center(center, (world.x - center.x).abs() * 2.0, initial.height()),
        }
    }

    fn asymmetric_bounds(&self, world: Point, lock_aspect: bool) -> Rect {
        if lock_aspect {
            return self.aspect_locked_bounds(world);
        }
        let (handle, initial) = (self.kind(), &self.initial_bounds);
        Rect::from_points(
            Point::new(
                if handle.moves_left() { world.x } else { initial.left },
                if handle.moves_top() { world.y } else { initial.top },
            ),
            Point::new(
                if handle.moves_right() { world.x } else { initial.right },
                if handle.moves_bottom() { world.y } else { initial.bottom },
            ),
        )
    }

    fn aspect_locked_bounds(&self, world: Point) -> Rect {
        let (handle, initial, ratio) = (self.kind(), &self.initial_bounds, self.aspect_ratio());
        let anchored = |anchor: Point| rect_from_anchor_with_aspect_ratio(anchor, world, ratio);
        match handle {
            H::TopLeft => anchored(initial.bottom_right()),
            H::TopRight => anchored(initial.bottom_left()),
            H::BottomRight => anchored(initial.top_left()),
            H::BottomLeft => anchored(initial.top_right()),
            H::Top | H::Right | H::Bottom | H::Left => {
                let edges = ResizeEdges {
                    top: handle.moves_top(),
                    bottom: handle.moves_bottom(),
                    left: handle.moves_left(),
                    right: handle.moves_right(),
                };
                edge_resize_with_aspect_ratio(*initial, world, edges, ratio)
            }
        }
    }
}

fn reference_for(handle: H, bounds: &Rect) -> Point {
    match handle {
        H::TopLeft | H::Top | H::Left => bounds.top_left(),
        H::TopRight => bounds.top_right(),
        H::Right | H::BottomRight | H::Bottom => bounds.bottom_right(),
        H::BottomLeft => bounds.bottom_left(),
    }
}

impl InteractionState for ResizeState {
    fn on_enter(&mut self, cx: &mut Cx) -> bool {
        self.snapshot = cx.ctx.document.node(self.handle.node).cloned();
        cx.txn.begin(cx.ctx, "Resize", &[self.handle.node]).is_ok()
    }

    fn resolve_cursor(&self, _ctx: &EditorContext, _world: Point) -> EditorCursor {
        cursor_for_resize_handle(self.kind())
    }

    fn on_pointer_move(&mut self, cx: &mut Cx, ev: &Ptr) -> Option<Transition> {
        let lock_aspect = ev.shift() || (self.policy.lock_corner_aspect && self.kind().is_corner());
        let bounds = self.new_bounds(ev.world - self.resize_offset, lock_aspect, ev.alt());
        let node = cx.ctx.document.node_mut(self.handle.node)?;
        if let Some(snapshot) = &self.snapshot {
            *node = snapshot.clone();
        }
        node.resize(bounds);
        None
    }

    fn on_pointer_up(&mut self, _cx: &mut Cx, _ev: &Ptr) -> Option<Transition> {
        Transition::to(IdleInteractionState)
    }
}

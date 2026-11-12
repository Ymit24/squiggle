//! Hit target resolution shared by the interaction states (`helpers.dart`).

use super::hit_target::HitTarget;
use super::selection_resize_handle::SelectionResizeHandle;
use super::{polyline_handle_util, resize_handle_util};
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::tool::EditorCursor;

pub fn target_under_cursor(ctx: &EditorContext, world: Point) -> HitTarget {
    if let [id] = ctx.selection.selected_node_ids()
        && let Some(node) = ctx.document.node(*id)
    {
        if let Some(handle) = polyline_handle_util::hit_test(node, world, &ctx.camera) {
            return HitTarget::PolylineHandle(handle);
        }
        if let Some(handle) = resize_handle_util::hit_test(node, world, &ctx.camera) {
            return HitTarget::ResizeHandle(handle);
        }
    }
    match ctx.document.node_at_point(world) {
        Some(node) => HitTarget::Node(node.id()),
        None => HitTarget::Canvas,
    }
}

pub fn cursor_for_resize_handle(handle: SelectionResizeHandle) -> EditorCursor {
    use SelectionResizeHandle::*;
    match handle {
        TopLeft => EditorCursor::ResizeUpLeft,
        Top => EditorCursor::ResizeUp,
        TopRight => EditorCursor::ResizeUpRight,
        Right => EditorCursor::ResizeRight,
        BottomRight => EditorCursor::ResizeDownRight,
        Bottom => EditorCursor::ResizeDown,
        BottomLeft => EditorCursor::ResizeDownLeft,
        Left => EditorCursor::ResizeLeft,
    }
}

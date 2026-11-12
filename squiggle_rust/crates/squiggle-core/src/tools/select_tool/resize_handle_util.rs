//! Resize handle geometry and hit testing (`resize_handle_util.dart`).

use super::resize_handle::ResizeHandle;
use super::resize_policy::ResizePolicy;
use super::selection_resize_handle::SelectionResizeHandle::{self, *};
use super::{SELECTION_BOX_PADDING, SELECTION_HANDLE_HIT_SIZE};
use crate::camera::Camera;
use crate::geom::{Point, Rect, Size};
use crate::node::Node;

pub fn hit_test(node: &Node, world_point: Point, camera: &Camera) -> Option<ResizeHandle> {
    let screen_point = camera.world_to_screen(world_point);
    resize_handles(node, camera).into_iter().find(|h| h.geometry.contains(screen_point))
}

/// The handles offered for `node`, with hit regions in screen coordinates.
pub fn resize_handles(node: &Node, camera: &Camera) -> Vec<ResizeHandle> {
    let screen_bounds = camera.world_to_screen_bounds(node.local_bounds());
    let inflated = screen_bounds.inflate(SELECTION_BOX_PADDING / camera.zoom);
    let half = SELECTION_HANDLE_HIT_SIZE / 2.0;
    let corner = Size::new(SELECTION_HANDLE_HIT_SIZE, SELECTION_HANDLE_HIT_SIZE);
    let horizontal = Size::new(inflated.width(), SELECTION_HANDLE_HIT_SIZE);
    let vertical = Size::new(SELECTION_HANDLE_HIT_SIZE, inflated.height());
    let center = inflated.center();

    let entries = [
        (TopLeft, inflated.top_left() - Point::new(half, half), corner),
        (Top, Point::new(center.x, inflated.top), horizontal),
        (TopRight, inflated.top_right() + Point::new(half, -half), corner),
        (Right, Point::new(inflated.right, center.y), vertical),
        (BottomRight, inflated.bottom_right() + Point::new(half, half), corner),
        (Bottom, Point::new(center.x, inflated.bottom), horizontal),
        (BottomLeft, inflated.bottom_left() + Point::new(-half, half), corner),
        (Left, Point::new(inflated.left, center.y), vertical),
    ];
    let policy = ResizePolicy::of(node);
    entries
        .into_iter()
        .filter(|(handle, ..)| is_offered(policy, *handle))
        .map(|(handle, center, size)| ResizeHandle {
            node: node.id(),
            handle,
            geometry: Rect::from_center(center, size.width, size.height),
        })
        .collect()
}

fn is_offered(policy: ResizePolicy, handle: SelectionResizeHandle) -> bool {
    policy.vertical_sides || !matches!(handle, Top | Bottom)
}

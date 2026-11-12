//! What is under the pointer (`hit_target.dart`).

use super::polyline_handle::PolylineHandle;
use super::resize_handle::ResizeHandle;
use crate::ids::NodeId;

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum HitTarget {
    Canvas,
    Node(NodeId),
    ResizeHandle(ResizeHandle),
    PolylineHandle(PolylineHandle),
}

//! A resize handle hit region of a node (`resize_handle.dart`).

use super::selection_resize_handle::SelectionResizeHandle;
use crate::geom::Rect;
use crate::ids::NodeId;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct ResizeHandle {
    pub node: NodeId,
    pub handle: SelectionResizeHandle,
    /// Hit region in screen coordinates.
    pub geometry: Rect,
}

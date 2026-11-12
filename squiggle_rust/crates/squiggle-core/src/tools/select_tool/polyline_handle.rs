//! A polyline vertex handle hit region (`polyline_handle.dart`).

use crate::geom::Rect;
use crate::ids::NodeId;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct PolylineHandle {
    pub feature: NodeId,
    pub point_index: usize,
    /// Hit region in screen coordinates.
    pub geometry: Rect,
}

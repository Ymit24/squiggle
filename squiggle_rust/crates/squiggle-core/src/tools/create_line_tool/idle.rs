use super::{LineState, Next};
use crate::geom::Point;

pub(super) fn on_pointer_down(world: Point) -> Next {
    Next::To(LineState::PendingPointer { start: world })
}

//! Distinguishes the initial click from dragging a new two-point line.

use super::placing::Placing;
use super::{LineCore, LineState, Next, TOUCH_SLOP, dragging};
use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::tool::Modifiers;

pub(super) fn on_pointer_move(
    start: Point,
    core: &mut LineCore,
    ctx: &mut EditorContext,
    world: Point,
    camera: &Camera,
    mods: Modifiers,
) -> Next {
    if world.distance(start) <= camera.screen_length_to_world_length(TOUCH_SLOP) {
        return Next::Stay;
    }
    dragging::on_pointer_move(start, core, ctx, world, mods);
    Next::To(LineState::Dragging { start })
}

pub(super) fn on_pointer_up(start: Point, world: Point) -> Next {
    Next::To(LineState::Placing(Placing::new(vec![start], world)))
}

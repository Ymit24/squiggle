use super::{LineCore, Next};
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::tool::Modifiers;

pub(super) fn on_pointer_move(start: Point, core: &mut LineCore, ctx: &mut EditorContext, world: Point, mods: Modifiers) {
    let end = core.constrained_point(start, world, mods.shift);
    core.update_preview(ctx, &[start, end]);
}

pub(super) fn on_pointer_up(start: Point, core: &mut LineCore, ctx: &mut EditorContext, world: Point, mods: Modifiers) -> Next {
    let end = core.constrained_point(start, world, mods.shift);
    core.finish(ctx, &[start, end])
}

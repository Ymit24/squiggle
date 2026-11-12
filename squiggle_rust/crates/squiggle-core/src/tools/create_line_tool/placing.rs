//! Click-to-place vertices; Enter, Escape or double click finishes.

use super::{LineCore, Next};
use crate::editor::context::EditorContext;
use crate::geom::Point;
use crate::tools::tool::Modifiers;

pub(super) struct Placing {
    pub points: Vec<Point>,
    preview_tip: Point,
    is_pointer_down: bool,
}

impl Placing {
    pub fn new(points: Vec<Point>, preview_tip: Point) -> Self {
        Placing { points, preview_tip, is_pointer_down: false }
    }

    fn with_tip(&self, tip: Point) -> Vec<Point> {
        self.points.iter().copied().chain([tip]).collect()
    }

    pub fn on_enter(&mut self, core: &mut LineCore, ctx: &EditorContext) {
        core.update_preview(ctx, &self.with_tip(self.preview_tip));
    }

    pub fn on_pointer_down(&mut self, core: &mut LineCore, ctx: &EditorContext, world: Point) -> Next {
        self.is_pointer_down = true;
        core.update_preview(ctx, &self.with_tip(world));
        Next::Stay
    }

    pub fn on_pointer_move(&mut self, core: &mut LineCore, ctx: &EditorContext, world: Point, mods: Modifiers) -> Next {
        if self.is_pointer_down {
            self.update_tip(core, ctx, world, mods);
        }
        Next::Stay
    }

    pub fn on_pointer_up(&mut self, core: &mut LineCore, ctx: &EditorContext, world: Point, mods: Modifiers) -> Next {
        if !self.is_pointer_down {
            return Next::Stay;
        }
        self.is_pointer_down = false;
        let last = self.points.last().copied().unwrap_or(world);
        self.points.push(core.constrained_point(last, world, mods.shift));
        core.update_preview(ctx, &self.with_tip(world));
        Next::Stay
    }

    pub fn on_pointer_hover(&mut self, core: &mut LineCore, ctx: &EditorContext, world: Point, mods: Modifiers) -> Next {
        self.update_tip(core, ctx, world, mods);
        Next::Stay
    }

    fn update_tip(&self, core: &mut LineCore, ctx: &EditorContext, world: Point, mods: Modifiers) {
        let last = self.points.last().copied().unwrap_or(world);
        core.update_preview(ctx, &self.with_tip(core.constrained_point(last, world, mods.shift)));
    }
}

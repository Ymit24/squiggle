//! Document viewport: draws the display list and routes pointer/wheel input to the tool model.

use crate::render;
use crate::state::State;
use crate::theme;
use rune::{Drag, El, Phase, Tx, WheelEvent, canvas, el};
use squiggle_core::geom::{Point, Size};
use squiggle_core::paint::Painter;
use squiggle_core::editor::tool_model::ToolModel;
use squiggle_core::tools::tool::Modifiers;

pub fn view(s: &State) -> El {
    let ctx = &s.ctx;
    let mut painter = Painter::new();
    for n in ctx.document.nodes() {
        n.paint(&mut painter);
    }
    if let Some(tool) = ctx.tool.active() {
        tool.paint(ctx, &ctx.camera, &mut painter);
    }
    let list = painter.commands;
    let mut v = el().key("viewport").w_full().grow(1.0).fill(theme::base()).clip_soft(0.0);
    v = v.child(canvas(render::shape(&list, &ctx.camera)).key("scene").w_full().h_full().absolute(0.0, 0.0));
    for t in render::text_elements(&list, &ctx.camera) {
        v = v.child(t);
    }
    v.on_layout(|s: &mut State, r| s.ctx.viewport_size = Size::new(r[2] as f64, r[3] as f64))
        .on_drag(|s: &mut State, d: &mut Drag, _tx: &mut Tx| {
            let world = s.ctx.camera.screen_to_world(Point::new(d.x as f64, d.y as f64));
            let cam = s.ctx.camera;
            let mods = Modifiers::default();
            match d.phase {
                Phase::Down => ToolModel::on_pointer_down(&mut s.ctx, world, &cam, mods),
                Phase::Up => ToolModel::on_pointer_up(&mut s.ctx, world, &cam, mods),
                _ => ToolModel::on_pointer_move(&mut s.ctx, world, &cam, mods),
            };
            s.autosave_if_changed();
        })
        .on_wheel(|s: &mut State, e: WheelEvent, _tx: &mut Tx| {
            s.ctx.camera.pan_by_screen_delta(Point::new(e.dx as f64, e.dy as f64));
            true
        })
}

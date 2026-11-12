//! Document viewport: draws the display list and routes pointer/wheel/pinch input to the tool
//! model and camera (port of `document_viewport.dart` / `editor_interactions.dart`).

use crate::render;
use crate::state::State;
use crate::theme;
use rune::{Cursor, Drag, El, MagnifyEvent, Phase, PointerButton, PointerEvent, Tx, WheelEvent, canvas, el};
use squiggle_core::editor::tool_model::ToolModel;
use squiggle_core::geom::{Point, Size};
use squiggle_core::paint::Painter;
use squiggle_core::tools::tool::{EditorCursor, Modifiers};

/// Secondary-button drags shorter than this open the context menu instead of panning.
const SECONDARY_DRAG_THRESHOLD: f32 = 5.0;

fn mouse_cursor(c: EditorCursor) -> Cursor {
    match c {
        EditorCursor::Basic => Cursor::Default,
        EditorCursor::Grab => Cursor::Grab,
        EditorCursor::Grabbing => Cursor::Grabbing,
        EditorCursor::Crosshair => Cursor::Crosshair,
        EditorCursor::ResizeLeft | EditorCursor::ResizeRight => Cursor::ResizeColumn,
        EditorCursor::ResizeUp | EditorCursor::ResizeDown => Cursor::ResizeRow,
        _ => Cursor::Move,
    }
}

fn world(s: &State, x: f32, y: f32) -> Point {
    s.ctx.camera.screen_to_world(Point::new(x as f64, y as f64))
}

fn modifiers(s: &State) -> Modifiers {
    s.editor_ui.mods
}

fn primary_drag(s: &mut State, d: &Drag) {
    let (w, cam, mods) = (world(s, d.x, d.y), s.ctx.camera, modifiers(s));
    s.editor_ui.pointer = Point::new(d.x as f64, d.y as f64);
    match d.phase {
        Phase::Down => ToolModel::on_pointer_down(&mut s.ctx, w, &cam, mods),
        Phase::Up if d.cancelled() => {
            s.ctx.cancel_interaction();
            false
        }
        Phase::Up => ToolModel::on_pointer_up(&mut s.ctx, w, &cam, mods),
        _ => ToolModel::on_pointer_move(&mut s.ctx, w, &cam, mods),
    };
    s.autosave_if_changed();
}

fn pan_drag(s: &mut State, d: &Drag, open_menu_on_click: bool) {
    match d.phase {
        Phase::Down => s.editor_ui.pan_origin = Some(s.ctx.camera.location),
        Phase::Up => {
            let clicked = d.dx.hypot(d.dy) < SECONDARY_DRAG_THRESHOLD;
            s.editor_ui.pan_origin = None;
            if open_menu_on_click && clicked {
                let screen = Point::new(d.x as f64, d.y as f64);
                s.editor_ui.context_menu = Some((screen, s.ctx.camera.screen_to_world(screen)));
            }
        }
        _ => {
            if let Some(origin) = s.editor_ui.pan_origin
                && d.dx.hypot(d.dy) >= SECONDARY_DRAG_THRESHOLD
            {
                s.ctx.camera.location = origin - Point::new(d.dx as f64, d.dy as f64) * s.ctx.camera.zoom;
            }
        }
    }
}

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
    let hover = world(s, s.editor_ui.pointer.x as f32, s.editor_ui.pointer.y as f32);
    let cursor = mouse_cursor(ToolModel::resolve_cursor(ctx, hover, &ctx.camera));
    let mut v = el().key("viewport").w_full().grow(1.0).fill(theme::base()).clip_soft(0.0).cursor(cursor);
    v = v.child(canvas(render::shape(&list, &ctx.camera)).key("scene").w_full().h_full().absolute(0.0, 0.0));
    for t in render::text_elements(&list, &ctx.camera) {
        v = v.child(t);
    }
    v.pointer_buttons([PointerButton::Secondary, PointerButton::Middle])
        .on_layout(|s: &mut State, r| s.ctx.viewport_size = Size::new(r[2] as f64, r[3] as f64))
        .on_pointer_move_local(|s: &mut State, p: PointerEvent, _tx: &mut Tx| {
            s.editor_ui.pointer = Point::new(p.x as f64, p.y as f64);
            let (w, cam, mods) = (world(s, p.x, p.y), s.ctx.camera, modifiers(s));
            ToolModel::on_pointer_hover(&mut s.ctx, w, &cam, mods);
        })
        .on_drag(|s: &mut State, d: &mut Drag, tx: &mut Tx| {
            match tx.button() {
                PointerButton::Primary => primary_drag(s, d),
                PointerButton::Secondary => pan_drag(s, d, true),
                _ => pan_drag(s, d, false),
            }
        })
        .on_double_press(|s: &mut State| {
            let (p, cam) = (s.editor_ui.pointer, s.ctx.camera);
            ToolModel::on_double_click(&mut s.ctx, cam.screen_to_world(p), &cam);
            s.autosave_if_changed();
        })
        .on_wheel(|s: &mut State, e: WheelEvent, _tx: &mut Tx| {
            let anchor = Point::new(e.x as f64, e.y as f64);
            if e.precise {
                // Trackpad scroll pans.
                s.ctx.camera.pan_by_screen_delta(Point::new(e.dx as f64, e.dy as f64));
            } else {
                // Mouse wheel zooms about the pointer.
                s.ctx.camera.zoom_toward(anchor, (-(e.dy as f64) * 0.002).exp());
            }
            true
        })
        .on_magnify(|s: &mut State, e: MagnifyEvent, _tx: &mut Tx| {
            let anchor = Point::new(e.x as f64, e.y as f64);
            s.ctx.camera.zoom_toward(anchor, 1.0 / (1.0 + e.delta as f64).max(0.05));
            true
        })
}

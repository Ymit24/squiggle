//! Shows the brush wheel at the pointer while B is held and activates the hovered brush when B
//! is released (port of `brush_wheel_host.dart`).
//!
//! Rune has no focus-stealing host widget, so the key handling stays with the editor's window
//! key handler: call [`open`] on B down, [`close`] with `commit: true` on B up and
//! `commit: false` on Escape or when the window deactivates, and feed pointer movement over the
//! editor to [`track_pointer`] while the wheel is closed (the open wheel tracks the pointer
//! itself). Render [`layer`] (or `inspector::overlays`) above the editor.

use super::wheel::brush_wheel;
use crate::inspector::brush_name_dialog::open_create;
use crate::inspector::brush_ops;
use crate::inspector::WheelState;
use crate::state::State;
use rune::{El, PointerEvent, Tx, el};
use squiggle_core::brush_wheel_geometry as geo;
use squiggle_core::geom::Point;

const EDGE_MARGIN: f64 = 8.0;

pub fn is_open(s: &State) -> bool {
    s.inspector_ui.wheel.is_some()
}

fn brush_count(s: &State) -> usize {
    s.ctx.document.session.brushes.len()
}

/// The wheel ends with a "new brush" slot until the document is full.
fn slot_count(s: &State) -> usize {
    brush_count(s) + usize::from(s.ctx.document.session.can_create_brush())
}

/// Mirrors the Cmd/Ctrl+number brush shortcut: brushes only apply to new drawings, so the wheel
/// is unavailable with a selection, a non-drawing tool, an inline text edit or a held modifier.
pub fn can_open(s: &State, has_modifier: bool) -> bool {
    let ctx = &s.ctx;
    let drawing = ctx.tool.active().is_some_and(|t| t.create_drawing_kind().is_some());
    !has_modifier && drawing && ctx.selection.is_empty() && ctx.text_edit.session().is_none() && !is_open(s)
}

/// Opens the wheel at the last tracked pointer position (or the viewport centre).
pub fn open(s: &mut State, has_modifier: bool) -> bool {
    if !can_open(s, has_modifier) {
        return false;
    }
    let Some(kind) = s.ctx.tool.active().and_then(|t| t.create_drawing_kind()) else { return false };
    let viewport = s.ctx.viewport_size;
    let pointer = s.inspector_ui.pointer.unwrap_or_else(|| Point::new(viewport.width / 2.0, viewport.height / 2.0));
    let center = geo::clamp_center(pointer, viewport, EDGE_MARGIN);
    let hovered = geo::slot_at(pointer - center, slot_count(s));
    s.inspector_ui.wheel = Some(WheelState { center, kind, hovered });
    true
}

/// Closes the wheel. With `commit`, the hovered brush becomes active (the add slot opens the
/// create dialog).
pub fn close(s: &mut State, commit: bool) {
    let Some(wheel) = s.inspector_ui.wheel.take() else { return };
    let Some(index) = wheel.hovered.filter(|_| commit) else { return };
    let session = &s.ctx.document.session;
    if index >= session.brushes.len() {
        if session.can_create_brush() {
            open_create(s);
        }
        return;
    }
    let id = session.brushes[index].id.clone();
    brush_ops::activate(&mut s.ctx, &id);
    s.autosave_if_changed();
}

/// Records the pointer (editor-local points; `None` when it left). While open it also moves the
/// hover.
pub fn track_pointer(s: &mut State, position: Option<Point>) {
    s.inspector_ui.pointer = position;
    let count = slot_count(s);
    if let Some(wheel) = &mut s.inspector_ui.wheel {
        wheel.hovered = position.and_then(|p| geo::slot_at(p - wheel.center, count));
    }
}

/// The wheel above a full-size layer that absorbs canvas input while open; empty when closed.
pub fn layer(s: &State) -> El {
    let Some(wheel) = &s.inspector_ui.wheel else { return el() };
    let session = &s.ctx.document.session;
    let picker = brush_wheel(
        &session.brushes,
        &session.active_brush().id,
        wheel.hovered,
        session.can_create_brush(),
        &wheel.kind,
    );
    let at = wheel.center - Point::new(geo::OUTER_RADIUS, geo::OUTER_RADIUS);
    el().key("brush-wheel-layer")
        .absolute(0.0, 0.0)
        .w_full()
        .h_full()
        .on_pointer_move_local(|s: &mut State, e: PointerEvent, _tx: &mut Tx| {
            track_pointer(s, Some(Point::new(e.x as f64, e.y as f64)));
        })
        .child(picker.absolute(at.x as f32, at.y as f32))
}

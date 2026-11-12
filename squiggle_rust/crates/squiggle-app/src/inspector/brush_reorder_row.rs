//! A named brush row: a click selects, dragging anywhere on it reorders (port of
//! `brush_reorder_row.dart`). The drop position follows the pointer travel in whole rows.

use super::brush_menu_entry::brush_menu_entry;
use super::brush_ops;
use super::metrics::BRUSH_ENTRY_HEIGHT;
use super::Reorder;
use crate::state::State;
use rune::{Drag, El, Phase, Tx, el};
use squiggle_core::session::{BrushProfile, MAX_BRUSHES};

/// Pointer travel below this many points is a click.
const CLICK_SLOP: f32 = 4.0;

/// `index` is the row's place among the named brushes (Scratch excluded).
pub fn brush_reorder_row(brush: &BrushProfile, index: usize, selected: bool, dragging: bool) -> El {
    let number = (index + 2 <= MAX_BRUSHES).then_some(index + 2);
    let id = brush.id.clone();
    let mut entry = brush_menu_entry(brush, selected, number);
    if dragging {
        entry = entry.fill(crate::theme::mantle()).border(1.0, crate::theme::surface1());
    }
    el().key(format!("brush-drag-{}", brush.id))
        .w_full()
        .child(entry)
        .on_drag(move |s: &mut State, d: &mut Drag, _tx: &mut Tx| on_drag(s, d, &id, index))
}

/// The row's `index` changes while a drag previews the new order, so only `Down` trusts it; the
/// rest of the gesture works from the [`Reorder`] it recorded.
fn on_drag(s: &mut State, d: &Drag, id: &str, index: usize) {
    match d.phase {
        Phase::Down => s.inspector_ui.reorder = Some(Reorder { id: id.to_owned(), from: index, target: index }),
        Phase::Move => {
            let named = s.ctx.document.session.brushes.len().saturating_sub(1);
            if let Some(reorder) = &mut s.inspector_ui.reorder {
                let rows = (d.dy / BRUSH_ENTRY_HEIGHT).round() as i64;
                reorder.target = (reorder.from as i64 + rows).clamp(0, named.saturating_sub(1) as i64) as usize;
            }
        }
        Phase::Up => finish(s, d, id),
    }
}

fn finish(s: &mut State, d: &Drag, id: &str) {
    let Some(reorder) = s.inspector_ui.reorder.take() else { return };
    if d.cancelled() {
        return;
    }
    if d.dy.abs() < CLICK_SLOP {
        brush_ops::activate(&mut s.ctx, id);
        s.inspector_ui.picker_open = false;
    } else if reorder.target != reorder.from {
        brush_ops::move_brush(&mut s.ctx, id, reorder.target + 1);
    }
    s.autosave_if_changed();
}

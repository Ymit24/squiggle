//! Delete confirmation (port of `delete_brush_dialog.dart`).

use super::brush_ops;
use super::dialog::{ButtonVariant, dialog, dialog_button};
use super::{BrushDialog, close_dialog};
use crate::kit::BODY;
use crate::state::State;
use crate::theme;
use rune::{El, text};

pub fn open_delete(s: &mut State) {
    let brush = s.ctx.document.session.active_brush();
    let (id, name) = (brush.id.clone(), brush.name.clone());
    s.inspector_ui.actions_open = false;
    s.inspector_ui.picker_open = false;
    s.inspector_ui.dialog = Some(BrushDialog::Delete { id, name });
}

fn confirm(s: &mut State) {
    if let Some(BrushDialog::Delete { id, .. }) = s.inspector_ui.dialog.clone() {
        brush_ops::delete(&mut s.ctx, &id);
    }
    close_dialog(s);
    s.autosave_if_changed();
}

pub fn delete_brush_dialog(name: &str) -> El {
    let body = text(format!("Delete \"{name}\"? Existing objects will keep their styles."))
        .font(BODY)
        .color(theme::text())
        .wrap();
    dialog(
        "brush-delete",
        "Delete brush?",
        body,
        vec![
            dialog_button("brush-delete-cancel", "Cancel", ButtonVariant::Ghost, true, close_dialog),
            dialog_button("brush-delete-confirm", "Delete", ButtonVariant::Danger, true, confirm),
        ],
        close_dialog,
    )
}

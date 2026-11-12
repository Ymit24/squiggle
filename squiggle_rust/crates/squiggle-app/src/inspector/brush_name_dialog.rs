//! Create / rename brush dialog (port of `brush_name_dialog.dart`).

use super::brush_ops;
use super::dialog::{ButtonVariant, dialog, dialog_button};
use super::{BrushDialog, close_dialog};
use crate::kit::BODY;
use crate::state::State;
use crate::theme;
use rune::{El, TextEdit, text_input};

fn open_with(s: &mut State, dialog: BrushDialog, initial: &str) {
    let ui = &mut s.inspector_ui;
    ui.picker_open = false;
    ui.actions_open = false;
    ui.name_edit = TextEdit::new(initial);
    // Autofocused fields select their initial text for easy replacement.
    ui.name_edit.anchor = 0;
    ui.name_edit.focus = initial.len();
    ui.name_edit.focused = true;
    ui.dialog = Some(dialog);
}

/// Prompts for a name and creates a brush from the active one.
pub fn open_create(s: &mut State) {
    let source_id = s.ctx.document.session.active_brush().id.clone();
    open_with(s, BrushDialog::Create { source_id }, "");
}

pub fn open_rename(s: &mut State) {
    let brush = s.ctx.document.session.active_brush();
    let (id, name) = (brush.id.clone(), brush.name.clone());
    open_with(s, BrushDialog::Rename { id }, &name);
}

/// Applies the dialog, unless the active brush changed or the document filled up while it was
/// open. An empty name keeps the dialog open.
pub fn submit(s: &mut State) {
    let name = s.inspector_ui.name_edit.text.trim().to_owned();
    if name.is_empty() {
        return;
    }
    match s.inspector_ui.dialog.clone() {
        Some(BrushDialog::Create { source_id }) => {
            let session = &s.ctx.document.session;
            if session.active_brush().id == source_id && session.can_create_brush() {
                let _ = brush_ops::create(&mut s.ctx, &name);
            }
        }
        Some(BrushDialog::Rename { id }) => brush_ops::rename(&mut s.ctx, &id, &name),
        _ => return,
    }
    close_dialog(s);
    s.autosave_if_changed();
}

pub fn brush_name_dialog(creating: bool, name_is_empty: bool, edit: &TextEdit) -> El {
    let field = text_input(edit, BODY)
        .key("brush-name-field")
        .single_line()
        .placeholder("Brush name", theme::subtext())
        .color(theme::text())
        .padding(10.0)
        .radius(crate::kit::metrics::INPUT_RADIUS)
        .fill(theme::surface0())
        .on_edit(|s: &mut State| &mut s.inspector_ui.name_edit)
        .on_submit(|s: &mut State, _| submit(s));
    let (title, action) = if creating { ("Create brush", "Create") } else { ("Rename brush", "Rename") };
    dialog(
        "brush-name",
        title,
        field,
        vec![
            dialog_button("brush-name-cancel", "Cancel", ButtonVariant::Ghost, true, close_dialog),
            dialog_button("brush-name-submit", action, ButtonVariant::Primary, !name_is_empty, submit),
        ],
        close_dialog,
    )
}

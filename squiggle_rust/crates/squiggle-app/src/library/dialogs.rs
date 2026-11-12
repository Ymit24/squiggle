//! The name dialog (new/rename) and delete confirmation (`document_name_dialog.dart`,
//! `delete_document_dialog.dart`).

use super::{LibraryUi, actions};
use crate::dialog::{Dialog, message};
use crate::kit::{ButtonVariant, StyledButton};
use crate::state::State;
use crate::text_field::TextField;
use crate::theme;
use rune::{El, Tx};

pub const NAME_FIELD_KEY: &str = "name-field";

pub fn name_dialog(title: &str, confirm_label: &str, ui: &LibraryUi) -> Vec<El> {
    let can_submit = !ui.name.text.trim().is_empty();
    let field = TextField::new(NAME_FIELD_KEY, "Canvas name").build::<State>(
        &ui.name,
        |s| &mut s.library_ui.name,
        Some(Box::new(|s: &mut State, _tx: &mut Tx| actions::submit_name_dialog(s))),
    );
    Dialog::new("name", title)
        .content(field)
        .action(StyledButton::new("dialog-cancel", "Cancel", ButtonVariant::Ghost).build(actions::close_overlay))
        .action(StyledButton::new("dialog-confirm", confirm_label, ButtonVariant::Primary).enabled(can_submit).build(actions::submit_name_dialog))
        .build(actions::close_overlay)
}

pub fn delete_dialog(name: &str) -> Vec<El> {
    Dialog::new("delete", "Delete canvas?")
        .glyph("!", theme::danger())
        .content(message(&format!("\"{name}\" will be permanently deleted. This cannot be undone.")))
        .action(StyledButton::new("dialog-cancel", "Cancel", ButtonVariant::Ghost).build(actions::close_overlay))
        .action(StyledButton::new("dialog-confirm", "Delete", ButtonVariant::Danger).build(actions::confirm_delete))
        .build(actions::close_overlay)
}

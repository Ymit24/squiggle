//! Library operations on the whole-app state: page switching and document management.

use super::{LibraryUi, Overlay};
use crate::state::{Page, State};
use crate::text_field::select_all;

/// Leaves the editor for the library: saves the open document, refreshes the list (so previews
/// and "edited" labels are current) and shows the library with a fresh search and sort.
pub fn open_library(s: &mut State) {
    s.library.save_current_document(&s.ctx);
    s.library.refresh_documents();
    s.library_ui = LibraryUi::default();
    s.page = Page::Library;
}

fn show_editor(s: &mut State) {
    s.saved_revision = s.ctx.revision();
    s.library_ui.overlay = Overlay::None;
    s.page = Page::Editor;
}

/// Opens `id` in the editor (`_openDocument`).
pub fn open_document(s: &mut State, id: &str) {
    s.library.open_document(id, &mut s.ctx);
    show_editor(s);
}

/// Creates a document (`name` or the default "Untitled") and opens it (`_createAndOpen`).
pub fn create_and_open(s: &mut State, name: Option<&str>) {
    s.library.create_document(name, &mut s.ctx);
    show_editor(s);
}

pub fn rename_document(s: &mut State, id: &str, name: &str) {
    let name = name.trim();
    if name.is_empty() {
        return;
    }
    s.library.rename_document(id, name);
    if s.library.current_document().is_some_and(|c| c.id == id) {
        s.ctx.document.name = name.to_owned();
    }
}

/// Deletes `id` (never the last document); the editor's document follows if it was the open one.
pub fn delete_document(s: &mut State, id: &str) {
    s.library.delete_document(id, &mut s.ctx);
    s.saved_revision = s.ctx.revision();
    s.library_ui.forget_preview(id);
}

fn open_name_dialog(s: &mut State, overlay: Overlay, initial: &str) {
    let name = &mut s.library_ui.name;
    name.replace_text(initial);
    select_all(name);
    name.focused = true;
    s.library_ui.overlay = overlay;
}

/// The "New canvas" dialog from the header button (`_createNamedDocument`).
pub fn open_new_dialog(s: &mut State) {
    open_name_dialog(s, Overlay::NewDialog, "Untitled");
}

pub fn open_rename_dialog(s: &mut State, id: &str) {
    let current = s.library.documents().iter().find(|d| d.id == id).map(|d| d.name.clone());
    if let Some(name) = current {
        open_name_dialog(s, Overlay::RenameDialog(id.to_owned()), &name);
    }
}

pub fn open_delete_dialog(s: &mut State, id: &str) {
    s.library_ui.overlay = Overlay::DeleteDialog(id.to_owned());
}

pub fn close_overlay(s: &mut State) {
    s.library_ui.overlay = Overlay::None;
}

/// Confirms the name dialog (Enter or the confirm button). An empty name does nothing.
pub fn submit_name_dialog(s: &mut State) {
    let name = s.library_ui.name.text.trim().to_owned();
    if name.is_empty() {
        return;
    }
    match std::mem::replace(&mut s.library_ui.overlay, Overlay::None) {
        Overlay::NewDialog => create_and_open(s, Some(&name)),
        Overlay::RenameDialog(id) => rename_document(s, &id, &name),
        other => s.library_ui.overlay = other,
    }
}

pub fn confirm_delete(s: &mut State) {
    if let Overlay::DeleteDialog(id) = std::mem::replace(&mut s.library_ui.overlay, Overlay::None) {
        delete_document(s, &id);
    }
}

pub fn clear_search(s: &mut State) {
    s.library_ui.search.clear();
}

//! Whole-app state. Each UI area owns one sub-struct (defined in its own module) so areas can
//! evolve independently.

use crate::editor::EditorUi;
use crate::inspector::InspectorUi;
use crate::library::LibraryUi;
use squiggle_core::editor::context::EditorContext;
use squiggle_core::repositories::{DocumentLibraryRepository, DocumentStorage, ImageRepository, default_app_dir};
use squiggle_core::document::Document;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Page {
    Library,
    Editor,
}

pub struct State {
    pub page: Page,
    pub ctx: EditorContext,
    pub library: DocumentLibraryRepository,
    pub images: ImageRepository,
    pub library_ui: LibraryUi,
    pub editor_ui: EditorUi,
    pub inspector_ui: InspectorUi,
    /// `library.revision()` / `ctx.revision()` seen at the last autosave.
    pub saved_revision: u64,
}

impl State {
    /// App state rooted at `app_dir` (use [`default_app_dir`] in the real app, a temp dir in tests).
    pub fn new(app_dir: std::path::PathBuf) -> Self {
        let mut ctx = EditorContext::new(Document::default());
        let mut library = DocumentLibraryRepository::new(DocumentStorage::new(&app_dir));
        library.initialize(&mut ctx);
        let images = ImageRepository::in_app_dir(&app_dir);
        let _ = images.initialize();
        State {
            page: Page::Editor,
            ctx,
            library,
            images,
            library_ui: LibraryUi::default(),
            editor_ui: EditorUi::default(),
            inspector_ui: InspectorUi::default(),
            saved_revision: 0,
        }
    }

    pub fn default_dir() -> std::path::PathBuf {
        default_app_dir()
    }

    /// Keeps the inline text field in step with the core's text-edit session: a new session gets
    /// a fresh field (existing text pre-selected), a closed one drops it.
    pub fn sync_text_edit(&mut self) -> bool {
        let session = self.ctx.text_edit.session().cloned();
        if session == self.editor_ui.text_session {
            return false;
        }
        let started = session.is_some();
        if let Some(session) = &session {
            let mut edit = rune::TextEdit::new(session.initial_contents.clone());
            if session.feature_id().is_some() {
                edit.set_selection(0, edit.text.len());
            } else {
                edit.set_caret(0);
            }
            self.editor_ui.text = edit;
            self.editor_ui.text_focus_done = false;
        }
        self.editor_ui.text_session = session;
        started
    }

    /// [`autosave_if_changed`](Self::autosave_if_changed) plus focusing a freshly opened text field.
    pub fn after_edit(&mut self, tx: &mut rune::Tx) {
        if self.sync_text_edit() {
            tx.focus("text-edit", false);
        }
        self.autosave_if_changed();
    }

    /// Persist the open document if the editor changed since the last save.
    pub fn autosave_if_changed(&mut self) {
        self.sync_text_edit();
        let rev = self.ctx.revision();
        if rev != self.saved_revision {
            self.saved_revision = rev;
            self.library.autosave(&self.ctx);
        }
    }
}

use super::{DocumentInfo, DocumentStorage};
use crate::document::Document;

/// The editor side of the library: owns the active in-memory document.
pub trait DocumentHost {
    fn document(&self) -> &Document;
    /// Replaces the active document (and resets selection/history as the editor sees fit).
    fn load_document(&mut self, document: Document);
}

/// Manages the set of persisted documents and the active in-memory document.
///
/// There are no change streams: `revision` increments on every change the UI should
/// re-read, and the app calls [`autosave`](Self::autosave) when history or brushes change.
#[derive(Debug)]
pub struct DocumentLibraryRepository {
    storage: DocumentStorage,
    documents: Vec<DocumentInfo>,
    current: Option<DocumentInfo>,
    revision: u64,
}

impl DocumentLibraryRepository {
    pub fn new(storage: DocumentStorage) -> Self {
        DocumentLibraryRepository { storage, documents: Vec::new(), current: None, revision: 0 }
    }

    pub fn storage(&self) -> &DocumentStorage {
        &self.storage
    }

    pub fn documents(&self) -> &[DocumentInfo] {
        &self.documents
    }

    pub fn current_document(&self) -> Option<&DocumentInfo> {
        self.current.as_ref()
    }

    pub fn revision(&self) -> u64 {
        self.revision
    }

    /// Opens the active document, else the most recent one, else creates a fresh one.
    pub fn initialize(&mut self, host: &mut impl DocumentHost) {
        let _ = self.storage.initialize();
        self.documents = self.storage.list_documents();
        let active = self.storage.load_active_document_id();
        let target = active
            .filter(|id| self.documents.iter().any(|d| d.id == *id))
            .or_else(|| self.documents.first().map(|d| d.id.clone()));
        match target {
            Some(id) => self.open_internal(&id, false, host),
            None => {
                let created = self.storage.create_document(None);
                self.documents = self.storage.list_documents();
                self.current = Some(created.clone());
                self.load_into_host(&created.id, host);
                self.storage.save_active_document_id(&created.id);
            }
        }
        self.notify();
    }

    pub fn create_document(&mut self, name: Option<&str>, host: &mut impl DocumentHost) {
        self.save_current_document(host);
        let created = self.storage.create_document(name);
        self.documents = self.storage.list_documents();
        self.current = self.documents.iter().find(|d| d.id == created.id).cloned().or(Some(created.clone()));
        self.load_into_host(&created.id, host);
        self.storage.save_active_document_id(&created.id);
        self.notify();
    }

    pub fn open_document(&mut self, id: &str, host: &mut impl DocumentHost) {
        if self.current.as_ref().is_some_and(|c| c.id == id) {
            return;
        }
        self.open_internal(id, true, host);
        self.notify();
    }

    pub fn refresh_documents(&mut self) {
        self.documents = self.storage.list_documents();
        if let Some(current) = &self.current {
            if let Some(fresh) = self.documents.iter().find(|d| d.id == current.id) {
                self.current = Some(fresh.clone());
            }
        }
        self.notify();
    }

    pub fn save_current_document(&mut self, host: &impl DocumentHost) {
        let Some(current) = self.current.clone() else { return };
        self.storage.save_document(&current.id, host.document(), &current.name);
        self.documents = self.storage.list_documents();
        self.current = self.documents.iter().find(|d| d.id == current.id).cloned().or(Some(current));
    }

    pub fn rename_document(&mut self, id: &str, new_name: &str) {
        let trimmed = new_name.trim();
        if trimmed.is_empty() {
            return;
        }
        self.storage.rename_document(id, trimmed);
        self.documents = self.storage.list_documents();
        if let Some(current) = self.current.as_mut().filter(|c| c.id == id) {
            *current = current.with_name(trimmed);
        }
        self.notify();
    }

    /// Deletes a document; the last remaining one is never deleted.
    pub fn delete_document(&mut self, id: &str, host: &mut impl DocumentHost) {
        if self.documents.len() <= 1 {
            return;
        }
        let deleting_current = self.current.as_ref().is_some_and(|c| c.id == id);
        self.storage.delete_document(id);
        self.documents = self.storage.list_documents();
        if deleting_current {
            if let Some(first) = self.documents.first().map(|d| d.id.clone()) {
                self.open_internal(&first, false, host);
            }
        }
        self.notify();
    }

    /// Saves the active document and refreshes its metadata (call on history/brush changes).
    pub fn autosave(&mut self, host: &impl DocumentHost) {
        let Some(current) = self.current.clone() else { return };
        self.storage.save_document(&current.id, host.document(), &current.name);
        self.refresh_document_info(&current.id);
    }

    fn refresh_document_info(&mut self, id: &str) {
        let Some(info) = self.storage.read_document_info(id) else { return };
        let Some(slot) = self.documents.iter_mut().find(|d| d.id == id) else { return };
        *slot = info.clone();
        if let Some(current) = self.current.as_mut().filter(|c| c.id == id) {
            *current = info;
        }
        self.notify();
    }

    fn open_internal(&mut self, id: &str, save_current: bool, host: &mut impl DocumentHost) {
        if save_current {
            self.save_current_document(host);
        }
        let Some(info) = self.documents.iter().find(|d| d.id == id).cloned() else { return };
        self.current = Some(info);
        self.load_into_host(id, host);
        self.storage.save_active_document_id(id);
    }

    fn load_into_host(&self, id: &str, host: &mut impl DocumentHost) {
        let document = self.storage.load_document(id).map(|s| s.document);
        host.load_document(document.unwrap_or_default());
    }

    fn notify(&mut self) {
        self.revision += 1;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::feature::Feature;
    use crate::feature_kinds::rectangle::RectangleKind;
    use crate::geom::{Point, Size};
    use crate::repositories::test_util::TempDir;
    use crate::session::{BrushProfile, DocumentSession};
    use crate::{FeatureKind, Node};
    use serde_json::json;

    struct Host(Document);

    impl DocumentHost for Host {
        fn document(&self) -> &Document {
            &self.0
        }
        fn load_document(&mut self, document: Document) {
            self.0 = document;
        }
    }

    fn setup() -> (TempDir, DocumentLibraryRepository, Host) {
        let tmp = TempDir::new("library");
        let mut library = DocumentLibraryRepository::new(DocumentStorage::new(&tmp.0));
        let mut host = Host(Document::default());
        library.initialize(&mut host);
        (tmp, library, host)
    }

    #[test]
    fn initialize_creates_a_first_document() {
        let (_tmp, library, host) = setup();
        assert_eq!(library.documents().len(), 1);
        assert_eq!(library.current_document().unwrap().name, "Untitled");
        assert_eq!(host.0.name, "Untitled");
        assert_eq!(library.storage().load_active_document_id(), Some(library.documents()[0].id.clone()));
    }

    #[test]
    fn session_only_changes_autosave_and_stay_local_to_each_document() {
        let (_tmp, mut library, mut host) = setup();
        let first_id = library.current_document().unwrap().id.clone();
        let mut brush = BrushProfile::new("b1", "Construction");
        brush.values.insert("strokeWidth".into(), json!(3.0));
        host.0.session = DocumentSession::new(vec![brush], Some("b1".into()));
        library.autosave(&host);

        let saved = library.storage().load_document(&first_id).unwrap().document;
        assert_eq!(saved.session.active_brush_id, "b1");
        assert_eq!(saved.session.active_brush().values["strokeWidth"], json!(3.0));

        library.create_document(Some("Other"), &mut host);
        assert!(host.0.session.active_brush().is_scratch());
        assert!(host.0.session.active_brush().values.is_empty());
        library.open_document(&first_id, &mut host);
        assert_eq!(host.0.session.active_brush_id, "b1");
        assert_eq!(host.0.session.active_brush().values["strokeWidth"], json!(3.0));
    }

    #[test]
    fn switches_documents() {
        let (_tmp, mut library, mut host) = setup();
        library.create_document(Some("One"), &mut host);
        let rect = Feature::new(Point::new(0.0, 0.0), Size::new(10.0, 10.0), FeatureKind::Rectangle(RectangleKind::default()));
        host.0.insert(None, Node::Feature(rect), None).unwrap();
        assert_eq!(host.0.nodes().len(), 1);

        library.create_document(Some("Two"), &mut host);
        assert_eq!(library.current_document().unwrap().name, "Two");
        assert!(host.0.nodes().is_empty());

        let one = library.documents().iter().find(|d| d.name == "One").unwrap().id.clone();
        library.open_document(&one, &mut host);
        assert_eq!(library.current_document().unwrap().name, "One");
        assert_eq!(host.0.nodes().len(), 1);
    }

    #[test]
    fn does_not_delete_the_last_remaining_document() {
        let (_tmp, mut library, mut host) = setup();
        let id = library.documents()[0].id.clone();
        library.delete_document(&id, &mut host);
        assert_eq!(library.documents().len(), 1);
    }

    #[test]
    fn deleting_current_opens_another_and_rename_trims() {
        let (_tmp, mut library, mut host) = setup();
        library.create_document(Some("Two"), &mut host);
        let two = library.current_document().unwrap().id.clone();
        library.rename_document(&two, "  Renamed ");
        assert_eq!(library.current_document().unwrap().name, "Renamed");
        library.rename_document(&two, "   ");
        assert_eq!(library.current_document().unwrap().name, "Renamed");
        library.delete_document(&two, &mut host);
        assert_eq!(library.documents().len(), 1);
        assert_ne!(library.current_document().unwrap().id, two);
    }
}

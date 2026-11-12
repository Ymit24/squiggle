use super::{DocumentInfo, random_u24, unix_micros};
use crate::document::Document;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

const DOCUMENTS_DIR: &str = "documents";
const ACTIVE_DOCUMENT_FILE: &str = "active_document.txt";
const DEFAULT_DOCUMENT_NAME: &str = "Untitled";

/// A document read back from disk.
#[derive(Clone, Debug, PartialEq)]
pub struct StoredDocument {
    pub document: Document,
}

impl StoredDocument {
    pub fn name(&self) -> &str {
        &self.document.name
    }
}

/// Persists documents as individual JSON files in the app data directory.
///
/// Like the Dart app, persistence failures while saving are swallowed (autosave must never
/// crash the editor); reads of unreadable or old-format files yield `None`.
#[derive(Clone, Debug)]
pub struct DocumentStorage {
    dir: PathBuf,
}

impl DocumentStorage {
    pub fn new(storage_dir: impl Into<PathBuf>) -> Self {
        DocumentStorage { dir: storage_dir.into() }
    }

    pub fn dir(&self) -> &Path {
        &self.dir
    }

    pub fn initialize(&self) -> std::io::Result<()> {
        fs::create_dir_all(self.documents_dir())
    }

    /// All readable documents, most recently modified first.
    pub fn list_documents(&self) -> Vec<DocumentInfo> {
        let _ = self.initialize();
        let Ok(entries) = fs::read_dir(self.documents_dir()) else { return Vec::new() };
        let mut documents: Vec<DocumentInfo> = entries
            .flatten()
            .map(|e| e.path())
            .filter(|p| p.is_file() && p.extension().is_some_and(|e| e == "json"))
            .filter_map(|p| read_document_info(&p))
            .collect();
        documents.sort_by(|a, b| b.updated_at.cmp(&a.updated_at).then_with(|| a.id.cmp(&b.id)));
        documents
    }

    pub fn read_document_info(&self, id: &str) -> Option<DocumentInfo> {
        read_document_info(&self.document_file(id))
    }

    pub fn load_document(&self, id: &str) -> Option<StoredDocument> {
        let text = fs::read_to_string(self.document_file(id)).ok()?;
        Document::decode(&text).ok().map(|document| StoredDocument { document })
    }

    pub fn create_document(&self, name: Option<&str>) -> DocumentInfo {
        let _ = self.initialize();
        let id = generate_document_id();
        let name = name.map_or_else(|| self.next_untitled_name(), str::to_owned);
        self.save_document(&id, &Document::new(&name), &name);
        DocumentInfo { id, name, updated_at: SystemTime::now() }
    }

    /// Writes `document` under `id`, stored with `name` (overrides `document.name`).
    pub fn save_document(&self, id: &str, document: &Document, name: &str) {
        let mut json = document.to_json();
        json["name"] = name.into();
        if self.initialize().is_ok() {
            let _ = fs::write(self.document_file(id), json.to_string());
        }
    }

    pub fn rename_document(&self, id: &str, new_name: &str) {
        if let Some(stored) = self.load_document(id) {
            self.save_document(id, &stored.document, new_name);
        }
    }

    pub fn delete_document(&self, id: &str) {
        let _ = fs::remove_file(self.document_file(id));
    }

    pub fn load_active_document_id(&self) -> Option<String> {
        let id = fs::read_to_string(self.dir.join(ACTIVE_DOCUMENT_FILE)).ok()?;
        let id = id.trim();
        (!id.is_empty()).then(|| id.to_owned())
    }

    pub fn save_active_document_id(&self, id: &str) {
        if self.initialize().is_ok() {
            let _ = fs::write(self.dir.join(ACTIVE_DOCUMENT_FILE), id);
        }
    }

    fn documents_dir(&self) -> PathBuf {
        self.dir.join(DOCUMENTS_DIR)
    }

    fn document_file(&self, id: &str) -> PathBuf {
        self.documents_dir().join(format!("{id}.json"))
    }

    fn next_untitled_name(&self) -> String {
        let used: Vec<String> = self.list_documents().into_iter().map(|d| d.name).collect();
        if !used.iter().any(|n| n == DEFAULT_DOCUMENT_NAME) {
            return DEFAULT_DOCUMENT_NAME.to_owned();
        }
        let taken = |i: u32| used.iter().any(|n| *n == format!("{DEFAULT_DOCUMENT_NAME} {i}"));
        let index = (2..).find(|&i| !taken(i)).unwrap_or(2);
        format!("{DEFAULT_DOCUMENT_NAME} {index}")
    }
}

fn read_document_info(path: &Path) -> Option<DocumentInfo> {
    let updated_at = fs::metadata(path).ok()?.modified().ok()?;
    let document = Document::decode(&fs::read_to_string(path).ok()?).ok()?;
    let id = path.file_name()?.to_str()?.replace(".json", "");
    Some(DocumentInfo { id, name: document.name, updated_at })
}

fn generate_document_id() -> String {
    format!("doc_{}_{:06x}", unix_micros(), random_u24())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repositories::test_util::TempDir;
    use crate::session::{BrushProfile, DocumentSession};
    use serde_json::{Value, json};

    fn setup() -> (TempDir, DocumentStorage) {
        let tmp = TempDir::new("docs");
        let storage = DocumentStorage::new(&tmp.0);
        storage.initialize().unwrap();
        (tmp, storage)
    }

    #[test]
    fn creates_lists_loads_renames_and_deletes_documents() {
        let (_tmp, storage) = setup();
        let created = storage.create_document(Some("First"));
        assert_eq!(created.name, "First");

        let documents = storage.list_documents();
        assert_eq!(documents.len(), 1);
        assert_eq!(documents[0].id, created.id);

        let loaded = storage.load_document(&created.id).unwrap();
        assert!(loaded.document.nodes().is_empty());
        assert_eq!(loaded.name(), "First");

        storage.rename_document(&created.id, "Renamed");
        assert_eq!(storage.read_document_info(&created.id).unwrap().name, "Renamed");

        let second = storage.create_document(Some("Second"));
        assert_eq!(storage.list_documents().len(), 2);

        storage.delete_document(&second.id);
        assert_eq!(storage.list_documents().len(), 1);
        assert!(storage.load_document(&second.id).is_none());
    }

    #[test]
    fn brush_snapshots_survive_save_rename_and_reload() {
        let (_tmp, storage) = setup();
        let created = storage.create_document(Some("Brushes"));
        let mut brush = BrushProfile::new("b1", "Construction");
        brush.values.insert("strokeColor".into(), json!(0xFFFFAA00u32));
        brush.values.insert("strokeType".into(), json!("dashed"));
        let mut doc = Document::new("Brushes");
        doc.session = DocumentSession::new(vec![brush.clone()], Some("b1".into()));
        storage.save_document(&created.id, &doc, "Brushes");
        brush.values.insert("strokeWidth".into(), json!(3.0));
        doc.session = DocumentSession::new(vec![brush.clone()], Some("b1".into()));
        storage.save_document(&created.id, &doc, "Brushes");
        storage.rename_document(&created.id, "Renamed");

        let restored = storage.load_document(&created.id).unwrap().document;
        assert_eq!(restored.name, "Renamed");
        assert_eq!(restored.session.active_brush_id, "b1");
        assert_eq!(restored.session.active_brush().values, brush.values);
        assert!(restored.session.scratch().values.is_empty());
    }

    #[test]
    fn persists_and_restores_active_document_id() {
        let (_tmp, storage) = setup();
        assert_eq!(storage.load_active_document_id(), None);
        let created = storage.create_document(Some("Active"));
        storage.save_active_document_id(&created.id);
        assert_eq!(storage.load_active_document_id(), Some(created.id));
    }

    #[test]
    fn writes_version_2_and_rejects_older_document_versions() {
        let (tmp, storage) = setup();
        let created = storage.create_document(Some("Current"));
        let path = tmp.0.join(format!("documents/{}.json", created.id));
        let json: Value = serde_json::from_str(&fs::read_to_string(path).unwrap()).unwrap();
        assert_eq!(json["version"], 2);

        fs::write(tmp.0.join("documents/old.json"), r#"{"version":1,"name":"Old","nodes":[]}"#).unwrap();
        assert!(storage.load_document("old").is_none());
        assert!(storage.list_documents().iter().all(|d| d.id != "old"));
    }

    #[test]
    fn untitled_names_are_unique() {
        let (_tmp, storage) = setup();
        assert_eq!(storage.create_document(None).name, "Untitled");
        assert_eq!(storage.create_document(None).name, "Untitled 2");
        assert_eq!(storage.create_document(None).name, "Untitled 3");
    }
}

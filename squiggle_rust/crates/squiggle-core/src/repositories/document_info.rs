use std::time::SystemTime;

/// Metadata for a persisted document file.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DocumentInfo {
    pub id: String,
    pub name: String,
    pub updated_at: SystemTime,
}

impl DocumentInfo {
    pub fn with_name(&self, name: impl Into<String>) -> Self {
        DocumentInfo { name: name.into(), ..self.clone() }
    }
}

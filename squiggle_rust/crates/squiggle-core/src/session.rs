use serde_json::{Map, Value};

pub const SCRATCH_ID: &str = "scratch";
pub const MAX_BRUSHES: usize = 9;

/// A sparse set of appearance overrides keyed by inspector field key.
#[derive(Clone, Debug, PartialEq)]
pub struct BrushProfile {
    pub id: String,
    pub name: String,
    /// Serialized field values; unknown keys are retained across saves.
    pub values: Map<String, Value>,
}

impl BrushProfile {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        BrushProfile { id: id.into(), name: name.into(), values: Map::new() }
    }

    pub fn is_scratch(&self) -> bool {
        self.id == SCRATCH_ID
    }

    pub fn from_json(json: &Value) -> Result<Self, String> {
        Ok(BrushProfile {
            id: json.get("id").and_then(Value::as_str).ok_or("brush id")?.to_owned(),
            name: json.get("name").and_then(Value::as_str).ok_or("brush name")?.to_owned(),
            values: json.get("values").and_then(Value::as_object).cloned().unwrap_or_default(),
        })
    }

    pub fn to_json(&self) -> Value {
        serde_json::json!({ "id": self.id, "name": self.name, "values": self.values })
    }
}

/// Document-local editor state (brushes). Canvas nodes never reference these profiles.
#[derive(Clone, Debug, PartialEq)]
pub struct DocumentSession {
    pub brushes: Vec<BrushProfile>,
    pub active_brush_id: String,
}

impl Default for DocumentSession {
    fn default() -> Self {
        DocumentSession::new(Vec::new(), None)
    }
}

impl DocumentSession {
    /// Normalises like the Dart original: unique ids, a scratch brush named "Scratch" first,
    /// and an active id that exists.
    pub fn new(brushes: Vec<BrushProfile>, active_brush_id: Option<String>) -> Self {
        let mut seen = std::collections::HashSet::new();
        let mut brushes: Vec<BrushProfile> =
            brushes.into_iter().filter(|b| seen.insert(b.id.clone())).collect();
        if !brushes.iter().any(BrushProfile::is_scratch) {
            brushes.insert(0, BrushProfile::new(SCRATCH_ID, "Scratch"));
        }
        let pos = brushes.iter().position(BrushProfile::is_scratch).unwrap();
        let mut scratch = brushes.remove(pos);
        scratch.name = "Scratch".into();
        brushes.insert(0, scratch);
        let mut active = active_brush_id.unwrap_or_else(|| SCRATCH_ID.to_owned());
        if !brushes.iter().any(|b| b.id == active) {
            active = SCRATCH_ID.to_owned();
        }
        DocumentSession { brushes, active_brush_id: active }
    }

    pub fn can_create_brush(&self) -> bool {
        self.brushes.len() < MAX_BRUSHES
    }

    pub fn scratch(&self) -> &BrushProfile {
        self.brushes.iter().find(|b| b.is_scratch()).expect("scratch brush always present")
    }

    pub fn active_brush(&self) -> &BrushProfile {
        self.brushes.iter().find(|b| b.id == self.active_brush_id).expect("active brush exists")
    }

    pub fn from_json(json: &Value) -> Result<Self, String> {
        let brushes = match json.get("brushes").and_then(Value::as_array) {
            Some(list) => list.iter().map(BrushProfile::from_json).collect::<Result<Vec<_>, _>>()?,
            None => Vec::new(),
        };
        Ok(DocumentSession::new(
            brushes,
            json.get("activeBrushId").and_then(Value::as_str).map(str::to_owned),
        ))
    }

    pub fn to_json(&self) -> Value {
        serde_json::json!({
            "activeBrushId": self.active_brush_id,
            "brushes": self.brushes.iter().map(BrushProfile::to_json).collect::<Vec<_>>(),
        })
    }
}

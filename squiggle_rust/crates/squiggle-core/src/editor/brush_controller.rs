//! Mutates document-local brush preferences without touching canvas history.
//!
//! Stateless apart from a change counter: every method takes the [`DocumentSession`] (which lives
//! on `Document::session`) it edits, so there is no bound/rebound session to keep in sync.

use crate::session::{BrushProfile, DocumentSession, SCRATCH_ID};
use serde_json::Value;

#[derive(Debug, Default)]
pub struct BrushController {
    revision: u64,
}

// TODO(integrate): `apply_to(kind)` — apply the active brush's values to a feature kind through
// the inspector fields (needs `inspector/**` and `brush_apply` from the kinds area). Intended
// shape: `pub fn apply_to(&self, session: &DocumentSession, kind: &mut FeatureKind)`.

impl BrushController {
    pub fn new() -> Self {
        BrushController::default()
    }

    /// Bumped on every mutation; replaces Dart's `notifyListeners`.
    pub fn revision(&self) -> u64 {
        self.revision
    }

    fn changed(&mut self) {
        self.revision += 1;
    }

    fn profile_mut<'a>(session: &'a mut DocumentSession, id: &str) -> Option<&'a mut BrushProfile> {
        session.brushes.iter_mut().find(|b| b.id == id)
    }

    pub fn activate(&mut self, session: &mut DocumentSession, id: &str) {
        if session.active_brush_id == id || !session.brushes.iter().any(|b| b.id == id) {
            return;
        }
        session.active_brush_id = id.to_owned();
        self.changed();
    }

    /// Creates a brush copying the active brush's values and activates it.
    pub fn create(&mut self, session: &mut DocumentSession, name: &str) -> Result<BrushProfile, String> {
        if !session.can_create_brush() {
            return Err("A document can have at most nine brushes.".into());
        }
        let name = name.trim();
        if name.is_empty() {
            return Err("Brush name must not be empty.".into());
        }
        let brush = BrushProfile {
            id: new_brush_id(session),
            name: name.to_owned(),
            values: session.active_brush().values.clone(),
        };
        session.brushes.push(brush.clone());
        session.active_brush_id = brush.id.clone();
        self.changed();
        Ok(brush)
    }

    pub fn rename(&mut self, session: &mut DocumentSession, id: &str, name: &str) {
        let name = name.trim();
        match Self::profile_mut(session, id) {
            Some(brush) if !brush.is_scratch() && !name.is_empty() => brush.name = name.to_owned(),
            _ => return,
        }
        self.changed();
    }

    /// Deleting the active brush folds its values into Scratch and activates Scratch.
    pub fn delete(&mut self, session: &mut DocumentSession, id: &str) {
        let Some(index) = session.brushes.iter().position(|b| b.id == id) else { return };
        if session.brushes[index].is_scratch() {
            return;
        }
        if session.active_brush_id == id {
            let values = session.brushes[index].values.clone();
            if let Some(scratch) = Self::profile_mut(session, SCRATCH_ID) {
                scratch.values = values;
            }
            session.active_brush_id = SCRATCH_ID.to_owned();
        }
        session.brushes.remove(index);
        self.changed();
    }

    /// Moves a named brush to a final index in the full list, after Scratch.
    pub fn move_brush(&mut self, session: &mut DocumentSession, id: &str, to_index: usize) {
        let Some(old) = session.brushes.iter().position(|b| b.id == id) else { return };
        if old == 0 || to_index < 1 || to_index >= session.brushes.len() || old == to_index {
            return;
        }
        let brush = session.brushes.remove(old);
        session.brushes.insert(to_index, brush);
        self.changed();
    }

    /// Values are JSON-compatible, encoded by the owning inspector field.
    pub fn set_field(&mut self, session: &mut DocumentSession, key: &str, value: Value) {
        let id = session.active_brush_id.clone();
        if let Some(brush) = Self::profile_mut(session, &id) {
            brush.values.insert(key.to_owned(), value);
            self.changed();
        }
    }

    pub fn clear_field(&mut self, session: &mut DocumentSession, key: &str) {
        let id = session.active_brush_id.clone();
        let removed = Self::profile_mut(session, &id).and_then(|b| b.values.remove(key)).is_some();
        if removed {
            self.changed();
        }
    }
}

/// A random-looking unique id (v4 UUID layout) built from std hashing, avoiding a uuid dependency.
fn new_brush_id(session: &DocumentSession) -> String {
    use std::hash::{BuildHasher, Hasher};
    loop {
        let mut bytes = [0u8; 16];
        for chunk in bytes.chunks_mut(8) {
            let mut h = std::collections::hash_map::RandomState::new().build_hasher();
            h.write_u128(std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map_or(0, |d| d.as_nanos()));
            chunk.copy_from_slice(&h.finish().to_le_bytes());
        }
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        let hex: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
        let id = format!("{}-{}-{}-{}-{}", &hex[0..8], &hex[8..12], &hex[12..16], &hex[16..20], &hex[20..32]);
        if !session.brushes.iter().any(|b| b.id == id) {
            return id;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn setup() -> (BrushController, DocumentSession) {
        (BrushController::new(), DocumentSession::default())
    }

    #[test]
    fn create_copies_active_values_and_activates() {
        let (mut c, mut s) = setup();
        c.set_field(&mut s, "strokeWidth", json!(4));
        let b = c.create(&mut s, "  Bold ").unwrap();
        assert_eq!(b.name, "Bold");
        assert_eq!(s.active_brush_id, b.id);
        assert_eq!(s.active_brush().values["strokeWidth"], json!(4));
        assert!(c.create(&mut s, " ").is_err());
    }

    #[test]
    fn create_stops_at_nine_brushes() {
        let (mut c, mut s) = setup();
        for i in 0..8 {
            c.create(&mut s, &format!("b{i}")).unwrap();
        }
        assert!(c.create(&mut s, "extra").is_err());
        assert_eq!(s.brushes.len(), 9);
    }

    #[test]
    fn deleting_active_brush_folds_values_into_scratch() {
        let (mut c, mut s) = setup();
        let b = c.create(&mut s, "A").unwrap();
        c.set_field(&mut s, "k", json!("v"));
        c.delete(&mut s, &b.id);
        assert_eq!(s.active_brush_id, SCRATCH_ID);
        assert_eq!(s.scratch().values["k"], json!("v"));
        assert_eq!(s.brushes.len(), 1);
        c.delete(&mut s, SCRATCH_ID);
        assert_eq!(s.brushes.len(), 1);
    }

    #[test]
    fn rename_activate_move_and_clear() {
        let (mut c, mut s) = setup();
        let a = c.create(&mut s, "A").unwrap();
        let b = c.create(&mut s, "B").unwrap();
        c.rename(&mut s, &a.id, " Alpha ");
        c.rename(&mut s, SCRATCH_ID, "Nope");
        assert_eq!(s.brushes[1].name, "Alpha");
        assert_eq!(s.scratch().name, "Scratch");
        c.activate(&mut s, &a.id);
        assert_eq!(s.active_brush_id, a.id);
        c.move_brush(&mut s, &b.id, 1);
        assert_eq!(s.brushes[1].id, b.id);
        c.move_brush(&mut s, SCRATCH_ID, 2);
        assert_eq!(s.brushes[0].id, SCRATCH_ID);
        c.set_field(&mut s, "k", json!(1));
        let rev = c.revision();
        c.clear_field(&mut s, "missing");
        assert_eq!(c.revision(), rev);
        c.clear_field(&mut s, "k");
        assert!(s.active_brush().values.is_empty());
    }
}

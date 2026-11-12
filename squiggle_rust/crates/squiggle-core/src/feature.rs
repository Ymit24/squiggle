use crate::feature_kind::FeatureKind;
use crate::geom::{Point, Rect, Size};
use crate::ids::{NO_ID, NodeId};
use crate::paint::Painter;
use serde_json::{Value, json};

/// A drawable shape or label in world space (relative to its parent container).
#[derive(Clone, Debug, PartialEq)]
pub struct Feature {
    pub id: NodeId,
    pub origin: Point,
    pub size: Size,
    pub kind: FeatureKind,
    /// Set while the inline editor draws this feature's label in its place. Transient: never
    /// persisted and not compared by equality-based change detection (see `to_json`).
    pub hide_label: bool,
}

impl Feature {
    pub fn new(origin: Point, size: Size, kind: FeatureKind) -> Self {
        Feature { id: NO_ID, origin, size, kind, hide_label: false }
    }

    pub fn from_json(json: &Value) -> Result<Self, String> {
        let num = |k: &str| json.get(k).and_then(Value::as_f64).ok_or(format!("feature.{k}"));
        Ok(Feature {
            id: NodeId(json.get("id").and_then(Value::as_u64).ok_or("feature.id")? as u32),
            origin: Point::new(num("originX")?, num("originY")?),
            size: Size::new(num("width")?, num("height")?),
            kind: FeatureKind::from_json(json.get("content").ok_or("feature.content")?)?,
            hide_label: false,
        })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "type": "feature",
            "id": self.id.0,
            "originX": self.origin.x,
            "originY": self.origin.y,
            "width": self.size.width,
            "height": self.size.height,
            "content": self.kind.to_json(),
        })
    }

    pub fn width(&self) -> f64 {
        self.size.width
    }

    pub fn height(&self) -> f64 {
        self.size.height
    }

    pub fn local_bounds(&self) -> Rect {
        self.kind.bounds_for(self)
    }

    pub fn set_bounds(&mut self, bounds: Rect) {
        self.origin = bounds.top_left();
        self.size = bounds.size();
    }

    pub fn hit_test(&self, point: Point) -> bool {
        self.kind.hit_test(self, point)
    }

    pub fn intersects_rect(&self, rect: &Rect) -> bool {
        self.kind.intersects_rect(self, rect)
    }

    pub fn resize(&mut self, bounds: Rect) {
        let mut kind = std::mem::take(&mut self.kind);
        kind.apply_bounds(self, bounds);
        self.kind = kind;
    }

    pub fn paint(&self, painter: &mut Painter) {
        self.kind.paint(self, painter);
    }

    /// Copy with a fresh kind; `id` of `None` keeps this id.
    pub fn copy_with_id(&self, id: Option<NodeId>) -> Feature {
        Feature { id: id.unwrap_or(self.id), hide_label: false, ..self.clone() }
    }
}

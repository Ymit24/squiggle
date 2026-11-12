//! STUB: PolylineKind. To be fully ported from the Dart `feature_kind_polyline.dart`.
use crate::feature::Feature;
use crate::geom::{Point, Rect};
use crate::paint::Painter;
use serde_json::Value;

#[derive(Clone, Debug, PartialEq)]
pub struct PolylineKind {
    /// Placeholder: raw persisted content until the real fields are ported.
    pub raw: Value,
}

impl PolylineKind {
    pub fn from_json(content: &Value) -> Result<Self, String> {
        Ok(Self { raw: content.clone() })
    }

    pub fn to_json(&self) -> Value {
        self.raw.clone()
    }

    pub fn bounds_for(&self, feature: &Feature) -> Rect {
        Rect::from_origin_size(feature.origin, feature.size)
    }

    pub fn hit_test(&self, feature: &Feature, p: Point) -> bool {
        self.bounds_for(feature).contains(p)
    }

    pub fn intersects_rect(&self, feature: &Feature, rect: &Rect) -> bool {
        self.bounds_for(feature).overlaps(rect)
    }

    /// `feature.kind` is temporarily a default kind while this runs; mutate `feature` and `self`.
    pub fn apply_bounds(&mut self, feature: &mut Feature, bounds: Rect) {
        feature.set_bounds(bounds);
    }

    pub fn paint(&self, _feature: &Feature, _painter: &mut Painter) {}
}

impl Default for PolylineKind {
    fn default() -> Self {
        Self { raw: serde_json::json!({ "type": "polyline" }) }
    }
}

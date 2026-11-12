//! The closed set of feature kinds. Per-kind behaviour lives in `feature_kinds/*`; this enum only
//! dispatches, so the node/document/tool code stays agnostic of kind specifics.

use crate::feature::Feature;
use crate::feature_kinds::*;
use crate::geom::{Point, Rect};
use crate::paint::Painter;
use serde_json::Value;

#[derive(Clone, Debug, PartialEq)]
pub enum FeatureKind {
    Rectangle(RectangleKind),
    Circle(CircleKind),
    Text(TextKind),
    Polyline(PolylineKind),
    Image(ImageKind),
}

impl Default for FeatureKind {
    fn default() -> Self {
        FeatureKind::Rectangle(RectangleKind::default())
    }
}

macro_rules! dispatch {
    ($self:expr, $k:ident => $body:expr) => {
        match $self {
            FeatureKind::Rectangle($k) => $body,
            FeatureKind::Circle($k) => $body,
            FeatureKind::Text($k) => $body,
            FeatureKind::Polyline($k) => $body,
            FeatureKind::Image($k) => $body,
        }
    };
}

impl FeatureKind {
    /// Persisted `type` tag.
    pub fn type_name(&self) -> &'static str {
        match self {
            FeatureKind::Rectangle(_) => "rectangle",
            FeatureKind::Circle(_) => "circle",
            FeatureKind::Text(_) => "text",
            FeatureKind::Polyline(_) => "polyline",
            FeatureKind::Image(_) => "image",
        }
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        match content.get("type").and_then(Value::as_str) {
            Some("rectangle") => RectangleKind::from_json(content).map(FeatureKind::Rectangle),
            Some("circle") => CircleKind::from_json(content).map(FeatureKind::Circle),
            Some("text") => TextKind::from_json(content).map(FeatureKind::Text),
            Some("polyline") => PolylineKind::from_json(content).map(FeatureKind::Polyline),
            Some("image") => ImageKind::from_json(content).map(FeatureKind::Image),
            other => Err(format!("Unknown feature kind: {other:?}")),
        }
    }

    /// Persisted `content` object (includes the `type` tag).
    pub fn to_json(&self) -> Value {
        dispatch!(self, k => k.to_json())
    }

    pub fn bounds_for(&self, feature: &Feature) -> Rect {
        dispatch!(self, k => k.bounds_for(feature))
    }

    pub fn hit_test(&self, feature: &Feature, world_point: Point) -> bool {
        dispatch!(self, k => k.hit_test(feature, world_point))
    }

    pub fn intersects_rect(&self, feature: &Feature, rect: &Rect) -> bool {
        dispatch!(self, k => k.intersects_rect(feature, rect))
    }

    /// Called by [`Feature::resize`], which swaps a default kind into the feature while this runs.
    pub fn apply_bounds(&mut self, feature: &mut Feature, bounds: Rect) {
        dispatch!(self, k => k.apply_bounds(feature, bounds))
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        dispatch!(self, k => k.paint(feature, painter))
    }
}

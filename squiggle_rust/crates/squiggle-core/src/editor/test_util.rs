//! Shared helpers for tests of editor logic (stub feature kinds only).

use crate::document::Document;
use crate::feature::Feature;
use crate::feature_kind::FeatureKind;
use crate::geom::{Point, Size};
use crate::ids::NodeId;
use crate::node::Node;
use serde_json::Value;

/// A 10x10 default-kind feature at `(x, y)`.
pub fn rect_at(x: f64, y: f64) -> Node {
    Feature::new(Point::new(x, y), Size::new(10.0, 10.0), FeatureKind::default()).into()
}

/// Root node ids in paint order.
pub fn ids(doc: &Document) -> Vec<NodeId> {
    doc.nodes().iter().map(Node::id).collect()
}

/// Persisted form of the whole document, for before/after comparisons.
pub fn snapshot(doc: &Document) -> Value {
    doc.to_json()
}

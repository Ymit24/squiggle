//! Circle (ellipse) kind (`feature_kind_circle.dart`): like a rectangle but drawn as an oval,
//! with its label confined to the inscribed box.

use super::shape_style::ShapeStyle;
use crate::feature::Feature;
use crate::geom::{Point, Rect};
use crate::label_layout::{LabelLayout, grow_height_to_fit_label, inscribed_label_bounds};
use crate::paint::Painter;
use crate::painting::Contour;
use serde_json::Value;
use std::f64::consts::SQRT_2;

#[derive(Clone, Debug, Default, PartialEq)]
pub struct CircleKind {
    pub style: ShapeStyle,
}

impl CircleKind {
    pub fn new(style: ShapeStyle) -> Self {
        Self { style }
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        ShapeStyle::from_json(content).map(Self::new)
    }

    pub fn to_json(&self) -> Value {
        self.style.to_json("circle")
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

    /// Sets the label and grows the feature's height so the label fits the inscribed box.
    pub fn set_label(&mut self, feature: &mut Feature, value: &str) {
        self.style.label = value.to_owned();
        let bounds = inscribed_label_bounds(Rect::from_origin_size(feature.origin, feature.size));
        grow_height_to_fit_label(feature, value, bounds, SQRT_2);
    }

    pub fn label_layout(&self, feature: &Feature) -> LabelLayout {
        self.style.label_layout(inscribed_label_bounds(self.bounds_for(feature)))
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        let outline = Contour::ellipse(self.bounds_for(feature));
        let label = (!feature.hide_label).then(|| self.label_layout(feature));
        self.style.paint(painter, outline, label);
    }
}

#[cfg(test)]
mod tests {
    crate::feature_kinds::shape_style::shape_kind_tests!(CircleKind, "circle", "Hello circle");
}

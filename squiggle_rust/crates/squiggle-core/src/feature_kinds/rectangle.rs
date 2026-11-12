//! Rectangle kind (`feature_kind_rectangle.dart`): a labelled, fillable, strokable box.

use super::shape_style::ShapeStyle;
use crate::feature::Feature;
use crate::geom::{Point, Rect};
use crate::label_layout::{LabelLayout, grow_height_to_fit_label, padded_label_bounds};
use crate::paint::Painter;
use crate::painting::Contour;
use serde_json::Value;

#[derive(Clone, Debug, Default, PartialEq)]
pub struct RectangleKind {
    pub style: ShapeStyle,
}

impl RectangleKind {
    pub fn new(style: ShapeStyle) -> Self {
        Self { style }
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        ShapeStyle::from_json(content).map(Self::new)
    }

    pub fn to_json(&self) -> Value {
        self.style.to_json("rectangle")
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

    /// Sets the label and grows the feature's height so the wrapped label fits.
    pub fn set_label(&mut self, feature: &mut Feature, value: &str) {
        self.style.label = value.to_owned();
        let bounds = padded_label_bounds(Rect::from_origin_size(feature.origin, feature.size));
        grow_height_to_fit_label(feature, value, bounds, 1.0);
    }

    pub fn label_layout(&self, feature: &Feature) -> LabelLayout {
        self.style.label_layout(padded_label_bounds(self.bounds_for(feature)))
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        let outline = Contour::rect(self.bounds_for(feature));
        let label = (!feature.hide_label).then(|| self.label_layout(feature));
        self.style.paint(painter, outline, label);
    }
}

#[cfg(test)]
mod tests {
    crate::feature_kinds::shape_style::shape_kind_tests!(RectangleKind, "rectangle", "Hello rectangle");
}

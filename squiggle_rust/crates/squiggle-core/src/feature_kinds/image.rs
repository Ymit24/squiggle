//! Image kind (`feature_kind_image.dart`): a raster referenced by id, with an optional outline.
//!
//! Painting always emits the image command; the renderer decides what to show while the bytes
//! are not loaded (the Dart app drew a `surface1` placeholder and requested the image).

use crate::color::Color;
use crate::document_colors::TRANSPARENT_STROKE_COLOR;
use crate::feature::Feature;
use crate::geom::{Point, Rect};
use crate::inspector::{FieldControl, FieldValue, InspectorField};
use crate::paint::{Cap, Painter};
use crate::painting::{Contour, paint_stroke};
use crate::stroke_type::StrokeType;
use crate::stroke_width::DEFAULT_STROKE_WIDTH;
use crate::style_values::{decode_string, decode_style_color, decode_style_number, num};
use serde_json::{Value, json};

#[derive(Clone, Debug, PartialEq)]
pub struct ImageKind {
    pub image_id: String,
    pub stroke_color: Color,
    pub stroke_width: f64,
}

impl ImageKind {
    pub fn new(image_id: impl Into<String>) -> Self {
        Self {
            image_id: image_id.into(),
            stroke_color: TRANSPARENT_STROKE_COLOR,
            stroke_width: DEFAULT_STROKE_WIDTH,
        }
    }

    pub fn has_visible_stroke(&self) -> bool {
        self.stroke_color.a() > 0
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        Ok(Self {
            image_id: decode_string(content.get("imageId"), "imageId")?,
            stroke_color: decode_style_color(content.get("strokeColor"))?,
            stroke_width: decode_style_number(content.get("strokeWidth"))?,
        })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "type": "image",
            "imageId": self.image_id,
            "strokeColor": self.stroke_color.0,
            "strokeWidth": num(self.stroke_width),
        })
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

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        let bounds = self.bounds_for(feature);
        painter.image(&self.image_id, bounds);
        if self.has_visible_stroke() {
            let outline = [Contour::rect(bounds)];
            paint_stroke(painter, &outline, self.stroke_width, self.stroke_color, Cap::Butt, StrokeType::Solid);
        }
    }

    pub fn fields(&self) -> Vec<InspectorField> {
        vec![
            InspectorField::new("strokeColor", "Stroke Color", FieldControl::Color, FieldValue::Color(self.stroke_color)),
            InspectorField::new(
                "strokeWidth",
                "Stroke Width",
                FieldControl::StrokeWidth,
                FieldValue::Number(self.stroke_width),
            ),
        ]
    }

    pub fn set_field(&mut self, key: &str, value: &FieldValue) -> bool {
        match (key, *value) {
            ("strokeColor", FieldValue::Color(v)) => self.stroke_color = v,
            ("strokeWidth", FieldValue::Number(v)) => self.stroke_width = v,
            _ => return false,
        }
        true
    }
}

#[cfg(test)]
mod tests;

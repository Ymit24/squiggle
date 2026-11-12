//! Applying a brush's stored overrides to a feature kind (`BrushProfile.applyTo`).

use crate::feature::Feature;
use crate::feature_kind::FeatureKind;
use crate::session::BrushProfile;

/// Applying brush values to kinds and features.
pub trait BrushApply {
    /// Applies every stored value whose key matches one of `kind`'s inspector fields. Invalid
    /// values are skipped and unknown keys stay in the profile untouched.
    fn apply_to(&self, kind: &mut FeatureKind);

    /// Like [`BrushApply::apply_to`] for a placed feature: edits also keep its geometry
    /// consistent (e.g. a text feature's box refits after a font size override).
    fn apply_to_feature(&self, feature: &mut Feature);
}

impl BrushApply for BrushProfile {
    fn apply_to(&self, kind: &mut FeatureKind) {
        for field in kind.inspector_fields() {
            if let Some(raw) = self.values.get(field.key) {
                kind.apply_field_serialized(field.key, Some(raw), None);
            }
        }
    }

    fn apply_to_feature(&self, feature: &mut Feature) {
        for field in feature.kind.inspector_fields() {
            if let Some(raw) = self.values.get(field.key) {
                feature.apply_field_serialized(field.key, Some(raw));
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::color::Color;
    use crate::feature_kinds::{CircleKind, PolylineKind, RectangleKind, TextKind};
    use crate::fill_type::FillType;
    use crate::line_end_cap::LineEndCap;
    use crate::stroke_type::StrokeType;
    use crate::stroke_width::DEFAULT_STROKE_WIDTH;
    use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
    use serde_json::{Value, json};

    fn rectangle_source() -> FeatureKind {
        let mut rect = RectangleKind::default();
        let style = &mut rect.style;
        style.stroke_color = Color(0xFF12_3456);
        style.fill_color = Color(0x8876_5432);
        style.fill_type = FillType::Lines;
        style.stroke_type = StrokeType::Dashed;
        style.stroke_width = 3.0;
        style.label_font_size = 36.0;
        style.label_horizontal_alignment = TextHorizontalAlignment::Right;
        style.label_vertical_alignment = TextVerticalAlignment::Bottom;
        FeatureKind::Rectangle(rect)
    }

    fn circle_source() -> FeatureKind {
        let mut circle = CircleKind::default();
        circle.style.stroke_width = 16.0;
        FeatureKind::Circle(circle)
    }

    fn text_source() -> FeatureKind {
        let mut text = TextKind::new("Aa");
        text.font_size = 36.0;
        FeatureKind::Text(text)
    }

    fn polyline_source() -> FeatureKind {
        let mut line = PolylineKind::new(vec![]);
        line.start_end_cap = LineEndCap::Arrow;
        line.end_end_cap = LineEndCap::Arrow;
        FeatureKind::Polyline(line)
    }

    #[test]
    fn all_supported_inspector_fields_encode_and_apply_to_fresh_kinds() {
        let cases = [
            (rectangle_source(), FeatureKind::Rectangle(RectangleKind::default())),
            (circle_source(), FeatureKind::Circle(CircleKind::default())),
            (text_source(), FeatureKind::Text(TextKind::new("Unchanged content"))),
            (polyline_source(), FeatureKind::Polyline(PolylineKind::new(vec![]))),
        ];
        for (source, mut target) in cases {
            let fields = source.inspector_fields();
            let mut brush = BrushProfile::new("sample", "Sample");
            for field in &fields {
                brush.values.insert(field.key.to_owned(), field.encoded());
            }
            // Brushes persist through JSON.
            let reloaded = BrushProfile::from_json(&serde_json::from_str(&brush.to_json().to_string()).unwrap()).unwrap();
            assert_eq!(reloaded.values, brush.values);

            reloaded.apply_to(&mut target);

            let applied = target.inspector_fields();
            for field in &fields {
                let after = applied.iter().find(|f| f.key == field.key).map(|f| f.value);
                assert_eq!(after, Some(field.value), "{}", field.key);
            }
            if let FeatureKind::Text(text) = &target {
                assert_eq!(text.label, "Unchanged content");
            }
        }
    }

    #[test]
    fn invalid_overrides_leave_defaults_and_unknown_keys_survive() {
        let mut kind = FeatureKind::Rectangle(RectangleKind::default());
        let before = kind.to_json();
        let mut brush = BrushProfile::new("sample", "Sample");
        let values = json!({
            "strokeColor": "orange",
            "fillColor": -1,
            "strokeWidth": -4,
            "fontSize": f64::INFINITY,
            "strokeType": "future-stroke",
            "fillType": 42,
            "horizontalAlignment": null,
            "verticalAlignment": "unknown",
            "futureStyle": { "nested": ["preserved"] },
            "endEndCap": "arrow",
        });
        let Value::Object(map) = values else { panic!("object") };
        brush.values = map;

        brush.apply_to(&mut kind);

        assert_eq!(kind.to_json(), before);
        assert_eq!(brush.to_json()["values"]["futureStyle"], json!({ "nested": ["preserved"] }));
        let mut line = FeatureKind::Polyline(PolylineKind::new(vec![]));
        brush.apply_to(&mut line);
        let FeatureKind::Polyline(line) = line else { panic!("polyline") };
        assert_eq!(line.end_end_cap, LineEndCap::Arrow);
        assert_eq!(line.stroke_width, DEFAULT_STROKE_WIDTH);
    }
}

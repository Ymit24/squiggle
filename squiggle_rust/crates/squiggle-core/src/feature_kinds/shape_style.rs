//! Style shared by the labelled closed shapes (rectangle and circle).

use crate::color::Color;
use crate::document_colors::{DEFAULT_FEATURE_FILL_COLOR, DEFAULT_FEATURE_STROKE_COLOR, LABEL_COLOR};
use crate::fill_type::FillType;
use crate::inspector::{FieldControl, FieldValue, InspectorField};
use crate::label_layout::{LABEL_FONT_SIZE, LabelLayout};
use crate::geom::Rect;
use crate::paint::{Cap, Painter};
use crate::painting::{Contour, paint_fill, paint_stroke};
use crate::stroke_type::StrokeType;
use crate::stroke_width::DEFAULT_STROKE_WIDTH;
use crate::style_values::{
    decode_string, decode_style_color, decode_style_enum, decode_style_enum_or, decode_style_number, num,
};
use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
use serde_json::{Value, json};

#[derive(Clone, Debug, PartialEq)]
pub struct ShapeStyle {
    pub stroke_color: Color,
    pub fill_color: Color,
    pub fill_type: FillType,
    pub stroke_width: f64,
    pub stroke_type: StrokeType,
    pub label: String,
    pub label_font_size: f64,
    pub label_vertical_alignment: TextVerticalAlignment,
    pub label_horizontal_alignment: TextHorizontalAlignment,
}

impl Default for ShapeStyle {
    fn default() -> Self {
        ShapeStyle {
            stroke_color: DEFAULT_FEATURE_STROKE_COLOR,
            fill_color: DEFAULT_FEATURE_FILL_COLOR,
            fill_type: FillType::Solid,
            stroke_width: DEFAULT_STROKE_WIDTH,
            stroke_type: StrokeType::Solid,
            label: String::new(),
            label_font_size: LABEL_FONT_SIZE,
            label_vertical_alignment: TextVerticalAlignment::Center,
            label_horizontal_alignment: TextHorizontalAlignment::Center,
        }
    }
}

impl ShapeStyle {
    pub fn from_json(content: &Value) -> Result<Self, String> {
        let get = |key: &str| content.get(key);
        Ok(ShapeStyle {
            stroke_color: decode_style_color(get("strokeColor"))?,
            fill_color: decode_style_color(get("fillColor"))?,
            fill_type: decode_style_enum_or(get("fillType"), FillType::Solid),
            stroke_width: decode_style_number(get("strokeWidth"))?,
            stroke_type: decode_style_enum_or(get("strokeType"), StrokeType::Solid),
            label: decode_string(get("label"), "label")?,
            label_font_size: decode_style_number(get("labelFontSize"))?,
            label_vertical_alignment: decode_style_enum(get("labelVerticalAlignment"))?,
            label_horizontal_alignment: decode_style_enum(get("labelHorizontalAlignment"))?,
        })
    }

    pub fn to_json(&self, type_name: &str) -> Value {
        json!({
            "type": type_name,
            "strokeColor": self.stroke_color.0,
            "fillColor": self.fill_color.0,
            "fillType": self.fill_type.name(),
            "strokeWidth": num(self.stroke_width),
            "strokeType": self.stroke_type.name(),
            "label": self.label,
            "labelFontSize": num(self.label_font_size),
            "labelVerticalAlignment": self.label_vertical_alignment.name(),
            "labelHorizontalAlignment": self.label_horizontal_alignment.name(),
        })
    }

    pub fn fields(&self) -> Vec<InspectorField> {
        use FieldControl as C;
        use FieldValue as V;
        vec![
            InspectorField::new("strokeColor", "Stroke Color", C::Color, V::Color(self.stroke_color)),
            InspectorField::new("fillColor", "Fill Color", C::Color, V::Color(self.fill_color)),
            InspectorField::new("fillType", "Fill Type", C::FillType, V::FillType(self.fill_type)),
            InspectorField::new("strokeType", "Stroke Type", C::StrokeType, V::StrokeType(self.stroke_type)),
            InspectorField::new("strokeWidth", "Stroke Width", C::StrokeWidth, V::Number(self.stroke_width)),
            InspectorField::new("fontSize", "Font Size", C::FontSize, V::Number(self.label_font_size)),
            InspectorField::new(
                "verticalAlignment",
                "Vertical Alignment",
                C::VerticalAlignment,
                V::VerticalAlignment(self.label_vertical_alignment),
            ),
            InspectorField::new(
                "horizontalAlignment",
                "Horizontal Alignment",
                C::HorizontalAlignment,
                V::HorizontalAlignment(self.label_horizontal_alignment),
            ),
        ]
    }

    pub fn set_field(&mut self, key: &str, value: &FieldValue) -> bool {
        use FieldValue as V;
        match (key, *value) {
            ("strokeColor", V::Color(v)) => self.stroke_color = v,
            ("fillColor", V::Color(v)) => self.fill_color = v,
            ("fillType", V::FillType(v)) => self.fill_type = v,
            ("strokeType", V::StrokeType(v)) => self.stroke_type = v,
            ("strokeWidth", V::Number(v)) => self.stroke_width = v,
            ("fontSize", V::Number(v)) => self.label_font_size = v,
            ("verticalAlignment", V::VerticalAlignment(v)) => self.label_vertical_alignment = v,
            ("horizontalAlignment", V::HorizontalAlignment(v)) => self.label_horizontal_alignment = v,
            _ => return false,
        }
        true
    }

    pub fn label_layout(&self, label_bounds: Rect) -> LabelLayout {
        LabelLayout {
            bounds: label_bounds,
            font_size: self.label_font_size,
            color: LABEL_COLOR,
            horizontal_alignment: self.label_horizontal_alignment,
            vertical_alignment: self.label_vertical_alignment,
        }
    }

    /// Fill, outline, then (unless hidden) the label.
    pub fn paint(&self, painter: &mut Painter, outline: Contour, label: Option<LabelLayout>) {
        let contours = [outline];
        paint_fill(painter, &contours, self.fill_color, self.fill_type);
        paint_stroke(painter, &contours, self.stroke_width, self.stroke_color, Cap::Butt, self.stroke_type);
        if let Some(layout) = label {
            layout.paint(painter, &self.label);
        }
    }
}

#[cfg(test)]
macro_rules! shape_kind_tests {
    ($kind:ident, $type_name:literal, $label:literal) => {
        use super::*;
        use crate::feature_kind::FeatureKind;
        use crate::fill_type::FillType;
        use crate::geom::Size;
        use crate::paint::DrawCmd;
        use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
        use crate::color::Color;
        use serde_json::json;

        fn content() -> serde_json::Value {
            json!({
                "type": $type_name,
                "strokeColor": 0xFF112233u32,
                "fillType": "solid",
                "fillColor": 0xFF445566u32,
                "strokeType": "solid",
                "strokeWidth": 3.5,
                "label": $label,
                "labelFontSize": 18.0,
                "labelVerticalAlignment": "top",
                "labelHorizontalAlignment": "left",
            })
        }

        fn wrap(kind: $kind) -> FeatureKind {
            kind.into()
        }

        #[test]
        fn from_json_preserves_label_and_style_fields() {
            let kind = $kind::from_json(&content()).unwrap();
            let s = &kind.style;
            assert_eq!(s.label, $label);
            assert_eq!(s.stroke_color, Color(0xFF11_2233));
            assert_eq!(s.fill_color, Color(0xFF44_5566));
            assert_eq!(s.stroke_width, 3.5);
            assert_eq!(s.label_font_size, 18.0);
            assert_eq!(s.label_vertical_alignment, TextVerticalAlignment::Top);
            assert_eq!(s.label_horizontal_alignment, TextHorizontalAlignment::Left);
        }

        #[test]
        fn to_json_emits_type_label_and_style_fields() {
            let mut kind = $kind::default();
            let s = &mut kind.style;
            s.stroke_color = Color(0xFF11_2233);
            s.fill_color = Color(0xFF44_5566);
            s.stroke_width = 3.5;
            s.label = $label.to_owned();
            s.label_font_size = 18.0;
            s.label_vertical_alignment = TextVerticalAlignment::Top;
            s.label_horizontal_alignment = TextHorizontalAlignment::Left;
            assert_eq!(kind.to_json(), content());
        }

        #[test]
        fn round_trip_and_clone_preserve_everything() {
            let decoded = $kind::from_json(&content()).unwrap();
            assert_eq!($kind::from_json(&decoded.to_json()).unwrap(), decoded);
            assert_eq!(decoded.clone(), decoded);
        }

        #[test]
        fn uses_default_label_styling() {
            let s = $kind::default().style;
            assert!(s.label.is_empty());
            assert_eq!(s.label_font_size, 24.0);
            assert_eq!(s.label_vertical_alignment, TextVerticalAlignment::Center);
            assert_eq!(s.label_horizontal_alignment, TextHorizontalAlignment::Center);
        }

        #[test]
        fn fill_type_defaults_and_older_documents_use_solid() {
            assert_eq!($kind::default().style.fill_type, FillType::Solid);
            let mut data = $kind::default().to_json();
            data.as_object_mut().unwrap().remove("fillType");
            assert_eq!($kind::from_json(&data).unwrap().style.fill_type, FillType::Solid);
            data["fillType"] = json!("unknown");
            assert_eq!($kind::from_json(&data).unwrap().style.fill_type, FillType::Solid);
        }

        #[test]
        fn fill_type_round_trips_and_clones() {
            for fill_type in FillType::ALL {
                let mut kind = wrap($kind::default());
                assert!(kind.set_fill_type(*fill_type));
                assert_eq!(kind.to_json()["fillType"], fill_type.name());
                let decoded = FeatureKind::from_json(&kind.to_json()).unwrap();
                assert_eq!(decoded.fill_type(), Some(*fill_type));
                assert_eq!(kind.clone().fill_type(), Some(*fill_type));
            }
        }

        #[test]
        fn stroke_type_defaults_round_trips_and_clones() {
            use crate::stroke_type::StrokeType;
            let mut data = $kind::default().to_json();
            data.as_object_mut().unwrap().remove("strokeType");
            assert_eq!($kind::from_json(&data).unwrap().style.stroke_type, StrokeType::Solid);
            data["strokeType"] = json!("unknown");
            assert_eq!($kind::from_json(&data).unwrap().style.stroke_type, StrokeType::Solid);
            for stroke_type in StrokeType::ALL {
                let mut kind = wrap($kind::default());
                assert!(kind.set_stroke_type(*stroke_type));
                assert_eq!(kind.to_json()["strokeType"], stroke_type.name());
                assert_eq!(FeatureKind::from_json(&kind.to_json()).unwrap().stroke_type(), Some(*stroke_type));
                assert_eq!(kind.clone().stroke_type(), Some(*stroke_type));
            }
        }

        #[test]
        fn set_label_grows_height_but_keeps_origin_and_width() {
            let mut feature = Feature::new(Point::new(10.0, 20.0), Size::new(80.0, 20.0), wrap($kind::default()));
            feature.set_label("a long label that needs many lines to fit in the box");
            assert_eq!(feature.origin, Point::new(10.0, 20.0));
            assert_eq!(feature.width(), 80.0);
            assert!(feature.height() > 20.0);
        }

        #[test]
        fn set_label_does_not_shrink_height_when_label_fits_or_is_empty() {
            let mut feature = Feature::new(Point::ZERO, Size::new(200.0, 200.0), wrap($kind::default()));
            feature.set_label("short");
            assert_eq!(feature.height(), 200.0);
            feature.set_label("");
            assert_eq!(feature.height(), 200.0);
            assert_eq!(feature.kind.label(), Some(""));
        }

        fn invisible(label: &str) -> Feature {
            let mut kind = $kind::default();
            kind.style.label = label.to_owned();
            kind.style.fill_color = Color::TRANSPARENT;
            kind.style.stroke_color = Color::TRANSPARENT;
            Feature::new(Point::new(10.0, 10.0), Size::new(100.0, 60.0), wrap(kind))
        }

        fn painted(feature: &Feature) -> Vec<DrawCmd> {
            let mut painter = crate::paint::Painter::new();
            feature.paint(&mut painter);
            painter.commands
        }

        #[test]
        fn paints_a_non_empty_label_and_nothing_for_an_empty_one() {
            let cmds = painted(&invisible("label"));
            assert!(matches!(&cmds[..], [DrawCmd::Text { text, .. }] if text == "label"));
            assert!(painted(&invisible("")).is_empty());
        }

        #[test]
        fn hidden_label_is_not_painted() {
            let mut feature = invisible("label");
            feature.hide_label = true;
            assert!(painted(&feature).is_empty());
        }

        #[test]
        fn paints_fill_then_outline() {
            let mut kind = $kind::default();
            kind.style.fill_color = Color(0xFF00_FF00);
            let feature = Feature::new(Point::ZERO, Size::new(100.0, 60.0), wrap(kind));
            let cmds = painted(&feature);
            assert!(matches!(cmds[0], DrawCmd::Fill { .. }));
            assert!(matches!(cmds[1], DrawCmd::Stroke { closed: true, .. }));
        }
    };
}
#[cfg(test)]
pub(crate) use shape_kind_tests;

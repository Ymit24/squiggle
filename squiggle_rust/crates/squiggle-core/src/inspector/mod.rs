//! Inspector fields: the style properties a feature kind exposes for the style panel and brushes
//! (port of `inspector_field.dart` and the `inspector_*_field.dart` files).
//!
//! Dart models a field as an object holding value and callbacks. Here a field is plain data:
//!
//! * [`FeatureKind::inspector_fields`] lists a kind's [`InspectorField`]s: a stable `key`
//!   (also the key brushes store values under), a display `label`, the [`FieldControl`] that tells
//!   the UI what widget to show and how values are persisted, and the current [`FieldValue`].
//! * [`FieldValue::encode`] / [`FieldControl::decode`] convert to and from the persisted
//!   `serde_json::Value`.
//! * Edits go through [`Feature::apply_field`] (keeps geometry consistent, e.g. text refits) or
//!   [`FeatureKind::apply_field`] (kind only, as brushes do before a feature exists). The
//!   `*_serialized` variants silently ignore invalid values like Dart's `applySerialized`.
//! * [`fields_for_features`] merges the fields of a multi-selection (`byKeyForFeatures`):
//!   each [`MergedField`] holds every feature's value and reports `is_mixed`.

use crate::color::Color;
use crate::feature::Feature;
use crate::feature_kind::FeatureKind;
use crate::fill_type::FillType;
use crate::line_end_cap::LineEndCap;
use crate::stroke_type::StrokeType;
use crate::style_values::{
    decode_positive_number, decode_style_color, decode_style_enum, num,
};
use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
use serde_json::Value;

/// Which control a field is edited with; also decides how persisted values decode.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FieldControl {
    Color,
    StrokeWidth,
    FontSize,
    FillType,
    StrokeType,
    /// `is_start` selects which end of the line the control draws.
    EndCap { is_start: bool },
    HorizontalAlignment,
    VerticalAlignment,
}

/// A typed field value.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum FieldValue {
    Color(Color),
    Number(f64),
    FillType(FillType),
    StrokeType(StrokeType),
    EndCap(LineEndCap),
    HorizontalAlignment(TextHorizontalAlignment),
    VerticalAlignment(TextVerticalAlignment),
}

impl FieldValue {
    /// Persisted form (what brushes store): ARGB integer, number or enum name.
    pub fn encode(&self) -> Value {
        match *self {
            FieldValue::Color(c) => Value::from(c.0),
            FieldValue::Number(n) => num(n),
            FieldValue::FillType(v) => v.name().into(),
            FieldValue::StrokeType(v) => v.name().into(),
            FieldValue::EndCap(v) => v.name().into(),
            FieldValue::HorizontalAlignment(v) => v.name().into(),
            FieldValue::VerticalAlignment(v) => v.name().into(),
        }
    }
}

impl FieldControl {
    /// Decodes a persisted value; `Err` for invalid input (wrong type, unknown enum name,
    /// non-positive width/size, ...).
    pub fn decode(self, raw: Option<&Value>) -> Result<FieldValue, String> {
        Ok(match self {
            FieldControl::Color => FieldValue::Color(decode_style_color(raw)?),
            FieldControl::StrokeWidth | FieldControl::FontSize => FieldValue::Number(decode_positive_number(raw)?),
            FieldControl::FillType => FieldValue::FillType(decode_style_enum(raw)?),
            FieldControl::StrokeType => FieldValue::StrokeType(decode_style_enum(raw)?),
            FieldControl::EndCap { .. } => FieldValue::EndCap(decode_style_enum(raw)?),
            FieldControl::HorizontalAlignment => FieldValue::HorizontalAlignment(decode_style_enum(raw)?),
            FieldControl::VerticalAlignment => FieldValue::VerticalAlignment(decode_style_enum(raw)?),
        })
    }
}

/// One editable style property of a feature kind.
#[derive(Clone, Debug, PartialEq)]
pub struct InspectorField {
    /// Stable key (`strokeColor`, `fillColor`, `fillType`, `strokeType`, `strokeWidth`,
    /// `fontSize`, `verticalAlignment`, `horizontalAlignment`, `startEndCap`, `endEndCap`).
    pub key: &'static str,
    /// Display label.
    pub label: &'static str,
    pub control: FieldControl,
    pub value: FieldValue,
}

impl InspectorField {
    pub(crate) fn new(key: &'static str, label: &'static str, control: FieldControl, value: FieldValue) -> Self {
        InspectorField { key, label, control, value }
    }

    /// Persisted form of the current value.
    pub fn encoded(&self) -> Value {
        self.value.encode()
    }
}

/// A field shared by several selected features, with each feature's value in selection order.
#[derive(Clone, Debug, PartialEq)]
pub struct MergedField {
    pub key: &'static str,
    pub label: &'static str,
    pub control: FieldControl,
    pub values: Vec<FieldValue>,
}

impl MergedField {
    /// The first feature's value, which the UI shows as current.
    pub fn active_value(&self) -> FieldValue {
        self.values[0]
    }

    /// Whether the features disagree on this field.
    pub fn is_mixed(&self) -> bool {
        self.values.iter().any(|v| *v != self.values[0])
    }
}

/// Fields of all `features` grouped by key in first-seen order (`InspectorField.byKeyForFeatures`).
pub fn fields_for_features(features: &[&Feature]) -> Vec<MergedField> {
    let mut merged: Vec<MergedField> = Vec::new();
    for field in features.iter().flat_map(|f| f.kind.inspector_fields()) {
        match merged.iter_mut().find(|m| m.key == field.key) {
            Some(existing) => existing.values.push(field.value),
            None => merged.push(MergedField {
                key: field.key,
                label: field.label,
                control: field.control,
                values: vec![field.value],
            }),
        }
    }
    merged
}

/// Applies `value` to every feature that has a field `key`.
pub fn apply_field_to_features<'a>(
    features: impl IntoIterator<Item = &'a mut Feature>,
    key: &str,
    value: &FieldValue,
) {
    for feature in features {
        feature.apply_field(key, value);
    }
}

impl FeatureKind {
    /// Style fields for the inspector and brushes, in display order. Empty for kinds without any.
    pub fn inspector_fields(&self) -> Vec<InspectorField> {
        match self {
            FeatureKind::Rectangle(k) => k.style.fields(),
            FeatureKind::Circle(k) => k.style.fields(),
            FeatureKind::Text(k) => k.fields(),
            FeatureKind::Polyline(k) => k.fields(),
            FeatureKind::Image(k) => k.fields(),
        }
    }

    /// Sets field `key` on this kind only. With a `feature`, edits that change the kind's
    /// geometry (text font size and alignment) also refit that feature's box. Returns whether
    /// the key exists on this kind and `value` has the matching type.
    ///
    /// `feature` must be the feature that owns this kind *with the kind swapped out* (see
    /// [`Feature::apply_field`], which does that); for a free-standing kind pass `None`.
    pub fn apply_field(&mut self, key: &str, value: &FieldValue, feature: Option<&mut Feature>) -> bool {
        match self {
            FeatureKind::Rectangle(k) => k.style.set_field(key, value),
            FeatureKind::Circle(k) => k.style.set_field(key, value),
            FeatureKind::Text(k) => k.set_field(key, value, feature),
            FeatureKind::Polyline(k) => k.set_field(key, value),
            FeatureKind::Image(k) => k.set_field(key, value),
        }
    }

    /// Decodes `raw` for field `key` and applies it; invalid values and unknown keys leave the
    /// kind untouched (`applySerialized`). Returns whether anything was applied.
    pub fn apply_field_serialized(&mut self, key: &str, raw: Option<&Value>, feature: Option<&mut Feature>) -> bool {
        let Some(field) = self.inspector_fields().into_iter().find(|f| f.key == key) else { return false };
        match field.control.decode(raw) {
            Ok(value) => self.apply_field(key, &value, feature),
            Err(_) => false,
        }
    }
}

impl Feature {
    /// Edits style field `key`, keeping this feature's geometry consistent with the new style.
    pub fn apply_field(&mut self, key: &str, value: &FieldValue) -> bool {
        self.with_kind_taken(|kind, feature| kind.apply_field(key, value, Some(feature)))
    }

    /// Like [`Feature::apply_field`] from a persisted value; invalid values are ignored.
    pub fn apply_field_serialized(&mut self, key: &str, raw: Option<&Value>) -> bool {
        self.with_kind_taken(|kind, feature| kind.apply_field_serialized(key, raw, Some(feature)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::feature_kinds::{CircleKind, TextKind};
    use crate::geom::{Point, Size};
    use serde_json::json;

    fn circle_feature(width: f64, size: f64) -> Feature {
        let mut kind = CircleKind::default();
        kind.style.stroke_width = width;
        Feature::new(Point::ZERO, Size::new(size, size), FeatureKind::Circle(kind))
    }

    #[test]
    fn by_key_groups_fields_and_merges_values() {
        let first = circle_feature(1.0, 10.0);
        let mut second = circle_feature(3.0, 20.0);
        let fields = fields_for_features(&[&first, &second]);

        let keys: Vec<_> = fields.iter().map(|f| f.key).collect();
        assert_eq!(
            keys,
            [
                "strokeColor",
                "fillColor",
                "fillType",
                "strokeType",
                "strokeWidth",
                "fontSize",
                "verticalAlignment",
                "horizontalAlignment"
            ]
        );
        let width = fields.iter().find(|f| f.key == "strokeWidth").unwrap();
        assert_eq!(width.values, [FieldValue::Number(1.0), FieldValue::Number(3.0)]);
        assert!(width.is_mixed());
        assert!(!fields[0].is_mixed());

        apply_field_to_features([&mut second], "strokeWidth", &FieldValue::Number(5.0));
        assert_eq!(second.kind.stroke_width(), Some(5.0));
    }

    #[test]
    fn apply_field_updates_every_selected_feature() {
        let mut features = [circle_feature(1.0, 10.0), circle_feature(3.0, 20.0)];
        apply_field_to_features(features.iter_mut(), "strokeWidth", &FieldValue::Number(5.0));
        assert!(features.iter().all(|f| f.kind.stroke_width() == Some(5.0)));
    }

    #[test]
    fn encode_and_decode_round_trip() {
        let cases = [
            (FieldControl::Color, FieldValue::Color(Color(0x8812_3456))),
            (FieldControl::StrokeWidth, FieldValue::Number(3.5)),
            (FieldControl::FontSize, FieldValue::Number(36.0)),
            (FieldControl::FillType, FieldValue::FillType(FillType::Crosshatch)),
            (FieldControl::StrokeType, FieldValue::StrokeType(StrokeType::Dotted)),
            (FieldControl::EndCap { is_start: true }, FieldValue::EndCap(LineEndCap::Arrow)),
            (FieldControl::HorizontalAlignment, FieldValue::HorizontalAlignment(TextHorizontalAlignment::Right)),
            (FieldControl::VerticalAlignment, FieldValue::VerticalAlignment(TextVerticalAlignment::Bottom)),
        ];
        for (control, value) in cases {
            assert_eq!(control.decode(Some(&value.encode())), Ok(value));
        }
    }

    #[test]
    fn decode_rejects_invalid_values() {
        assert!(FieldControl::Color.decode(Some(&json!("orange"))).is_err());
        assert!(FieldControl::Color.decode(Some(&json!(-1))).is_err());
        assert!(FieldControl::Color.decode(Some(&json!(0x1_0000_0000u64))).is_err());
        assert!(FieldControl::StrokeWidth.decode(Some(&json!(-4))).is_err());
        assert!(FieldControl::FontSize.decode(Some(&json!(0))).is_err());
        assert!(FieldControl::FillType.decode(Some(&json!(42))).is_err());
        assert!(FieldControl::StrokeType.decode(Some(&json!("future-stroke"))).is_err());
        assert!(FieldControl::HorizontalAlignment.decode(Some(&Value::Null)).is_err());
        assert!(FieldControl::VerticalAlignment.decode(None).is_err());
    }

    #[test]
    fn text_font_size_edit_refits_the_box() {
        let kind = TextKind::new("hello");
        let size = kind.measure_contents(24.0, None, None);
        let mut feature = Feature::new(Point::ZERO, size, FeatureKind::Text(kind.clone()));

        assert!(feature.apply_field("fontSize", &FieldValue::Number(48.0)));

        assert_eq!(feature.size, kind.measure_contents(48.0, None, None));
    }

    #[test]
    fn mismatched_value_type_and_unknown_key_are_rejected() {
        let mut feature = circle_feature(1.0, 10.0);
        assert!(!feature.apply_field("strokeWidth", &FieldValue::Color(Color::WHITE)));
        assert!(!feature.apply_field("nope", &FieldValue::Number(1.0)));
        assert_eq!(feature.kind.stroke_width(), Some(1.0));
    }
}

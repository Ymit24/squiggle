//! Picks the selector widget for an inspector field from its [`FieldControl`] (the `build`
//! methods of the Dart `InspectorField` subclasses).

use super::color_row::color_row;
use super::fill_type_selector::fill_type_selector;
use super::font_size_selector::font_size_selector;
use super::line_end_cap_selector::line_end_cap_selector;
use super::stroke_type_selector::stroke_type_selector;
use super::stroke_width_selector::stroke_width_selector;
use super::text_horizontal_alignment_selector::text_horizontal_alignment_selector;
use super::text_vertical_alignment_selector::text_vertical_alignment_selector;
use crate::state::State;
use rune::El;
use squiggle_core::font_size_preset::FontSizePreset;
use squiggle_core::inspector::{FieldControl, FieldValue, InspectorField, MergedField};
use squiggle_core::stroke_width::StrokeWidthPreset;
use std::rc::Rc;

/// Called with the value a user picked.
pub type Apply = Rc<dyn Fn(&mut State, FieldValue)>;

/// What the UI needs of a field, whether it came from one feature kind (a drawing tool) or was
/// merged from a multi-selection.
pub struct FieldView {
    pub key: &'static str,
    pub control: FieldControl,
    pub active: FieldValue,
    pub mixed: bool,
}

impl From<&InspectorField> for FieldView {
    fn from(f: &InspectorField) -> Self {
        FieldView { key: f.key, control: f.control, active: f.value, mixed: false }
    }
}

impl From<&MergedField> for FieldView {
    fn from(f: &MergedField) -> Self {
        FieldView { key: f.key, control: f.control, active: f.active_value(), mixed: f.is_mixed() }
    }
}

/// The control for `field`; picking a value calls `apply` with the typed [`FieldValue`].
pub fn field_control(field: &FieldView, apply: Apply) -> El {
    let (key, mixed) = (field.key, field.mixed);
    match (field.control, field.active) {
        (FieldControl::Color, _) => {
            let color_apply = move |s: &mut State, c| apply(s, FieldValue::Color(c));
            color_row(key, None, true, Rc::new(color_apply))
        }
        (FieldControl::StrokeWidth, FieldValue::Number(n)) => {
            stroke_width_selector(key, StrokeWidthPreset::from_width(n), mixed, move |s, p| {
                apply(s, FieldValue::Number(p.width()))
            })
        }
        (FieldControl::FontSize, FieldValue::Number(n)) => {
            font_size_selector(key, FontSizePreset::from_size(n), mixed, move |s, p| apply(s, FieldValue::Number(p.size())))
        }
        (FieldControl::FillType, FieldValue::FillType(v)) => {
            fill_type_selector(key, Some(v), mixed, true, move |s, t| apply(s, FieldValue::FillType(t)))
        }
        (FieldControl::StrokeType, FieldValue::StrokeType(v)) => {
            stroke_type_selector(key, Some(v), mixed, true, move |s, t| apply(s, FieldValue::StrokeType(t)))
        }
        (FieldControl::EndCap { is_start }, FieldValue::EndCap(v)) => {
            line_end_cap_selector(key, Some(v), mixed, is_start, move |s, c| apply(s, FieldValue::EndCap(c)))
        }
        (FieldControl::HorizontalAlignment, FieldValue::HorizontalAlignment(v)) => {
            text_horizontal_alignment_selector(key, Some(v), mixed, true, move |s, a| {
                apply(s, FieldValue::HorizontalAlignment(a))
            })
        }
        (FieldControl::VerticalAlignment, FieldValue::VerticalAlignment(v)) => {
            text_vertical_alignment_selector(key, Some(v), mixed, true, move |s, a| {
                apply(s, FieldValue::VerticalAlignment(a))
            })
        }
        // A control whose value type disagrees (cannot come from the core): show nothing.
        _ => rune::el(),
    }
}

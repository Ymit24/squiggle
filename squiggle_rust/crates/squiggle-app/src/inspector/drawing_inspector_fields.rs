//! Fields of the active drawing tool's kind; picks edit the active brush, not the document
//! (port of `drawing_inspector_fields.dart`).

use super::brush_field_reset_button::brush_field_reset_button;
use super::brush_ops;
use super::field_control::{Apply, FieldView, field_control};
use super::field_shell::field_shell;
use super::metrics::PANEL_SECTION_SPACING;
use crate::state::State;
use rune::{El, col};
use squiggle_core::feature_kind::FeatureKind;
use std::rc::Rc;

pub fn drawing_inspector_fields(kind: &FeatureKind, active_brush_keys: &[String]) -> El {
    let fields = kind.inspector_fields().into_iter().map(|field| {
        let key = field.key;
        let apply: Apply = Rc::new(move |s: &mut State, value| brush_ops::set_field(&mut s.ctx, key, value.encode()));
        let overridden = active_brush_keys.iter().any(|k| k == key);
        let reset = overridden.then(|| {
            brush_field_reset_button(key, move |s: &mut State| brush_ops::clear_field(&mut s.ctx, key))
        });
        field_shell(field.label, reset, field_control(&FieldView::from(&field), apply))
    });
    col().gap(PANEL_SECTION_SPACING).children(fields)
}

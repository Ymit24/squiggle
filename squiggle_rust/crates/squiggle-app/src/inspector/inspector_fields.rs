//! Fields of the selected features, merged by key (port of `inspector_fields.dart`).
//! A pick edits every selected feature as one undoable "Inspector Update".

use super::edits::edit_selected_features;
use super::field_control::{Apply, FieldView, field_control};
use super::field_shell::field_shell;
use super::metrics::PANEL_SECTION_SPACING;
use crate::state::State;
use rune::{El, col};
use squiggle_core::feature::Feature;
use squiggle_core::inspector::fields_for_features;
use std::rc::Rc;

pub fn inspector_fields(features: &[&Feature]) -> El {
    let fields = fields_for_features(features).into_iter().map(|merged| {
        let key = merged.key;
        let apply: Apply = Rc::new(move |s: &mut State, value| {
            edit_selected_features(&mut s.ctx, "Inspector Update", |f| {
                f.apply_field(key, &value);
            });
            s.autosave_if_changed();
        });
        field_shell(merged.label, None, field_control(&FieldView::from(&merged), apply))
    });
    col().gap(PANEL_SECTION_SPACING).children(fields)
}

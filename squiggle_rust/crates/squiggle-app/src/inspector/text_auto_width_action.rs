//! Turns fixed-width text back into auto-width text (port of `text_auto_width_action.dart`).
//! Fixed width only comes from dragging, so the inspector offers just the way back.

use super::edits::edit_selected_features;
use super::field_shell::field_shell;
use crate::kit::{BODY, metrics};
use crate::state::State;
use crate::theme;
use rune::{El, row, text};
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::text_sizing::TextSizing;

/// Whether `features` are all fixed-width text, the only case the action applies to.
pub fn applies_to(features: &[&Feature]) -> bool {
    !features.is_empty()
        && features.iter().all(|f| matches!(&f.kind, FeatureKind::Text(t) if t.sizing == TextSizing::FixedWidth))
}

pub fn make_auto_width(s: &mut State) {
    edit_selected_features(&mut s.ctx, "Auto Width", |f| f.make_text_auto_width());
    s.autosave_if_changed();
}

pub fn text_auto_width_action() -> El {
    let button = row()
        .key("auto-width")
        .w_full()
        .h(32.0)
        .items_center()
        .justify_center()
        .radius(metrics::BUTTON_RADIUS)
        .border(1.0, theme::surface1())
        .hover(theme::surface1()).motion(rune::tok::motion::SNAPPY)
        .focusable(true)
        .on_press(make_auto_width)
        .child(text("Auto fit to text").font(BODY).color(theme::text()));
    field_shell("Textbox Width", None, button)
}

//! The preset colour swatches of a colour field (port of `color_row.dart`).
//!
//! Like the Dart original, both stroke and fill fields offer the presets' stroke colours and
//! no swatch is shown as active.

use super::metrics::SWATCH_GAP;
use super::style_swatch::Swatch;
use crate::state::State;
use crate::theme;
use rune::{El, row};
use squiggle_core::Color;
use squiggle_core::document_colors::STYLE_PRESETS;
use std::rc::Rc;

/// Swatches keyed `{key}-{index}`; index 0 is the transparent "none" colour.
pub fn color_row(key: &str, active_preset: Option<usize>, none_enabled: bool, on_select: Rc<dyn Fn(&mut State, Color)>) -> El {
    let swatches = STYLE_PRESETS.iter().enumerate().map(|(index, preset)| {
        let on_select = on_select.clone();
        let color = preset.stroke_color;
        let swatch = Swatch::new(format!("{key}-{index}")).active(active_preset == Some(index));
        let swatch = if index == 0 { swatch.enabled(none_enabled).help("None") } else { swatch.fill(theme::rune_color(color)) };
        swatch.build(move |s| on_select(s, color))
    });
    row().flex_wrap().gaps(SWATCH_GAP, SWATCH_GAP).children(swatches)
}

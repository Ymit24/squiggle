//! A row of single-choice swatches, the shape shared by every selector in the inspector.

use super::metrics::SWATCH_GAP;
use super::style_swatch::{Swatch, icon_color};
use crate::state::State;
use crate::theme;
use rune::{El, row};
use std::rc::Rc;

/// What a selector needs besides its options.
pub struct Choice<T> {
    /// The current value; ignored while `mixed`.
    pub active: Option<T>,
    pub mixed: bool,
    pub enabled: bool,
    pub on_select: Rc<dyn Fn(&mut State, T)>,
}

impl<T> Choice<T> {
    pub fn new(active: Option<T>, mixed: bool, on_select: impl Fn(&mut State, T) + 'static) -> Self {
        Choice { active, mixed, enabled: true, on_select: Rc::new(on_select) }
    }

    pub fn enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }
}

/// One swatch per value, keyed `{prefix}-{index}`. `help` is the tooltip and `overlay` draws the
/// glyph given whether the swatch is active.
pub fn choice_row<T: Copy + PartialEq + 'static>(
    prefix: &str,
    values: &[T],
    choice: Choice<T>,
    help: impl Fn(T) -> &'static str,
    overlay: impl Fn(T, bool) -> El,
) -> El {
    let swatches = values.iter().enumerate().map(|(index, &value)| {
        let active = !choice.mixed && choice.active == Some(value);
        let on_select = choice.on_select.clone();
        Swatch::new(format!("{prefix}-{index}"))
            .fill(theme::base())
            .active(active)
            .enabled(choice.enabled)
            .help(help(value))
            .overlay(overlay(value, active))
            .build(move |s| on_select(s, value))
    });
    row().gap(SWATCH_GAP).children(swatches)
}

/// Overlay colour for a swatch glyph.
pub fn glyph_color(active: bool) -> rune::Color {
    icon_color(active)
}

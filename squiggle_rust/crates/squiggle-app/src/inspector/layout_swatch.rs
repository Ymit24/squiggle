//! Icon button for align / distribute actions (port of `layout_swatch.dart`).

use super::style_swatch::{Swatch, centered};
use crate::state::State;
use crate::theme;
use rune::El;

pub fn layout_swatch(key: &str, tooltip: &str, icon: fn(rune::Color) -> El, on_press: impl Fn(&mut State) + 'static) -> El {
    Swatch::new(key).fill(theme::base()).help(tooltip).overlay(centered(icon(theme::subtext()))).build(on_press)
}

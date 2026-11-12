//! Two rows of align buttons (port of `node_align_selector.dart`).

use super::icons;
use super::layout_swatch::layout_swatch;
use super::metrics::SWATCH_GAP;
use crate::state::State;
use rune::{El, col, row};
use squiggle_core::node_layout::NodeAlignment as A;
use std::rc::Rc;

fn describe(a: A) -> (&'static str, &'static str, fn(rune::Color) -> El) {
    match a {
        A::Left => ("align-left", "Align left", icons::align_left),
        A::CenterHorizontal => ("align-center-horizontal", "Align center horizontally", icons::align_center_horizontal),
        A::Right => ("align-right", "Align right", icons::align_right),
        A::Top => ("align-top", "Align top", icons::align_top),
        A::CenterVertical => ("align-center-vertical", "Align center vertically", icons::align_center_vertical),
        A::Bottom => ("align-bottom", "Align bottom", icons::align_bottom),
    }
}

pub fn node_align_selector(on_align: Rc<dyn Fn(&mut State, A)>) -> El {
    let line = |items: [A; 3]| {
        row().gap(SWATCH_GAP).children(items.into_iter().map(|a| {
            let (key, tip, icon) = describe(a);
            let on_align = on_align.clone();
            layout_swatch(key, tip, icon, move |s| on_align(s, a))
        }))
    };
    col().gap(SWATCH_GAP).child(line([A::Left, A::CenterHorizontal, A::Right])).child(line([A::Top, A::CenterVertical, A::Bottom]))
}

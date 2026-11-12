//! Distribute buttons (port of `node_distribute_selector.dart`).

use super::icons;
use super::layout_swatch::layout_swatch;
use super::metrics::SWATCH_GAP;
use crate::state::State;
use rune::{El, row};
use squiggle_core::node_layout::NodeDistribution as D;
use std::rc::Rc;

pub fn node_distribute_selector(on_distribute: Rc<dyn Fn(&mut State, D)>) -> El {
    let items = [
        (D::Horizontal, "distribute-horizontal", "Distribute horizontally", icons::distribute_horizontal as fn(rune::Color) -> El),
        (D::Vertical, "distribute-vertical", "Distribute vertically", icons::distribute_vertical),
    ];
    row().gap(SWATCH_GAP).children(items.into_iter().map(|(d, key, tip, icon)| {
        let on_distribute = on_distribute.clone();
        layout_swatch(key, tip, icon, move |s| on_distribute(s, d))
    }))
}

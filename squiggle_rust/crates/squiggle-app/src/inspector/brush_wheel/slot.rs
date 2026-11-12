//! One brush on the wheel (port of `brush_wheel_slot.dart`).

use super::tile::brush_wheel_tile;
use crate::inspector::brush_sample::brush_swatch;
use crate::theme;
use rune::{El, el};
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::session::BrushProfile;

pub fn brush_wheel_slot(brush: &BrushProfile, kind: &FeatureKind, active: bool, hovered: bool) -> El {
    let mut content = el().key(format!("wheel-slot-{}", brush.id)).child(brush_swatch(&brush.values, kind, 48.0));
    if active {
        let dot = el().absolute(0.0, 0.0).pin(None, Some(4.0), Some(4.0), None).size(5.0, 5.0).radius(2.5).fill(theme::accent());
        content = content.child(dot);
    }
    brush_wheel_tile(hovered, active, content)
}

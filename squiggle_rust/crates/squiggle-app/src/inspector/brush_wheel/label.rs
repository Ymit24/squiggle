//! Names the pending change under the wheel: "Active -> Hovered", the current brush when it is
//! hovered, a new brush hint, or a cancel hint when nothing is (port of `brush_wheel_label.dart`).

use crate::kit::LABEL;
use crate::theme;
use rune::{El, row, text};
use squiggle_core::brush_wheel_geometry::LABEL_HEIGHT;
use squiggle_core::session::BrushProfile;

/// Text pieces of the label, each with whether it is muted.
pub fn label_parts(active: &BrushProfile, hovered: Option<&BrushProfile>, adding: bool) -> Vec<(String, bool)> {
    if adding {
        return vec![("New brush\u{2026}".into(), false)];
    }
    match hovered {
        None => vec![("Release to cancel".into(), true)],
        Some(target) if target.id == active.id => vec![(target.name.clone(), false), (" \u{b7} current".into(), true)],
        Some(target) => vec![(format!("{} \u{2192} ", active.name), true), (target.name.clone(), false)],
    }
}

pub fn brush_wheel_label(active: &BrushProfile, hovered: Option<&BrushProfile>, adding: bool) -> El {
    let parts = label_parts(active, hovered, adding).into_iter().map(|(content, muted)| {
        text(content).font(LABEL).color(if muted { theme::subtext() } else { theme::text() })
    });
    row()
        .key("brush-wheel-label")
        .h(LABEL_HEIGHT as f32)
        .px(10.0)
        .items_center()
        .radius(LABEL_HEIGHT as f32 / 2.0)
        .fill(theme::mantle())
        .border(1.0, theme::surface1())
        .children(parts)
}

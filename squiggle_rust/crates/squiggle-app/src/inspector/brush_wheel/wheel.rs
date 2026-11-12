//! The brush quick picker: one slot per brush around a cancel hub, plus a trailing "new brush"
//! slot when `can_create`, with the pending change named below. Purely visual; the host owns
//! input. A `hovered` index equal to `brushes.len()` is the new brush slot (port of
//! `brush_wheel.dart`).

use super::add_slot::brush_wheel_add_slot;
use super::label::brush_wheel_label;
use super::slot::brush_wheel_slot;
use crate::theme;
use rune::{Color, El, Shape, canvas, el, text};
use squiggle_core::brush_wheel_geometry as geo;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::geom::Point;
use squiggle_core::session::BrushProfile;
use std::f64::consts::TAU;

const DISC_ALPHA: f32 = 0.9;
const WEDGE_ALPHA: f32 = 0.14;
const ARC_STEPS: usize = 48;

fn on_circle(radius: f64, angle: f64) -> [f32; 2] {
    let c = geo::OUTER_RADIUS;
    [(c + radius * angle.cos()) as f32, (c + radius * angle.sin()) as f32]
}

/// The whole slice of `index` between the hub and the rim: the real hit area.
fn wedge(index: usize, count: usize) -> Vec<[f32; 2]> {
    let sweep = geo::sweep(count);
    let start = geo::slot_angle(index, count) - sweep / 2.0;
    let (outer, inner) = (geo::OUTER_RADIUS - 2.0, geo::INNER_RADIUS + 2.0);
    let arc = |radius: f64, from: f64, to: f64| (0..=ARC_STEPS).map(move |i| on_circle(radius, from + (to - from) * i as f64 / ARC_STEPS as f64));
    arc(outer, start, start + sweep).chain(arc(inner, start + sweep, start)).collect()
}

fn disc(slot_count: usize, hovered: Option<usize>) -> El {
    let rim = geo::OUTER_RADIUS - 1.0;
    let ring: Vec<[f32; 2]> = (0..96).map(|i| on_circle(rim, TAU * i as f64 / 96.0)).collect();
    let mut shape = Shape::new()
        .view_box(geo::DISC_SIZE.width as f32, geo::DISC_SIZE.height as f32)
        .fill(ring.clone(), theme::mantle().alpha(DISC_ALPHA))
        .stroke_with(ring, true, 1.0, rune::LineCap::Butt, theme::surface1());
    if let Some(index) = hovered {
        shape = shape.fill(wedge(index, slot_count), theme::accent().alpha(WEDGE_ALPHA));
    }
    canvas(shape).absolute(0.0, 0.0).size(geo::DISC_SIZE.width as f32, geo::DISC_SIZE.height as f32)
}

/// `tile` positioned at the centre of slot `index`.
fn at_slot(tile: El, index: usize, count: usize) -> El {
    let Point { x, y } = geo::slot_center(index, count);
    let half = geo::SLOT_SIZE / 2.0;
    el().absolute((geo::OUTER_RADIUS + x - half) as f32, (geo::OUTER_RADIUS + y - half) as f32)
        .size(geo::SLOT_SIZE as f32, geo::SLOT_SIZE as f32)
        .child(tile)
}

fn hub(show_cancel: bool) -> El {
    let radius = (geo::HUB_SIZE / 2.0) as f32;
    let at = (geo::OUTER_RADIUS as f32) - radius;
    let hub = el()
        .absolute(at, at)
        .size(radius * 2.0, radius * 2.0)
        .radius(radius)
        .fill(theme::mantle())
        .border(1.0, theme::surface1())
        .items_center()
        .justify_center();
    if show_cancel { hub.child(text("\u{d7}").color(theme::subtext())) } else { hub }
}

pub fn brush_wheel(
    brushes: &[BrushProfile],
    active_id: &str,
    hovered: Option<usize>,
    can_create: bool,
    kind: &FeatureKind,
) -> El {
    let count = brushes.len() + usize::from(can_create);
    let hovering_add = can_create && hovered == Some(brushes.len());
    let hovered_brush = hovered.filter(|_| !hovering_add).and_then(|i| brushes.get(i));
    let mut wheel = el()
        .key("brush-wheel")
        .size(geo::SIZE.width as f32, geo::SIZE.height as f32)
        .child(disc(count, hovered));
    for (index, brush) in brushes.iter().enumerate() {
        let slot = brush_wheel_slot(brush, kind, brush.id == active_id, hovered == Some(index));
        wheel = wheel.child(at_slot(slot, index, count));
    }
    if can_create {
        wheel = wheel.child(at_slot(brush_wheel_add_slot(hovering_add), brushes.len(), count));
    }
    let active = brushes.iter().find(|b| b.id == active_id).unwrap_or(&brushes[0]);
    let label = el()
        .absolute(0.0, (geo::OUTER_RADIUS * 2.0 + geo::LABEL_GAP) as f32)
        .w(geo::SIZE.width as f32)
        .h(geo::LABEL_HEIGHT as f32)
        .items_center()
        .justify_center()
        .child(brush_wheel_label(active, hovered_brush, hovering_add));
    wheel.child(hub(hovered.is_none())).child(label).fill(Color::TRANSPARENT)
}

//! Layout of the brush wheel in logical pixels, relative to its center
//! (port of `brush_wheel_geometry.dart`).
//!
//! Slot 0 sits at 12 o'clock and slots proceed clockwise, so slot order matches brush order
//! and the Cmd/Ctrl+number shortcuts.

use crate::geom::{Point, Size};
use std::f64::consts::PI;

/// Pointer distances below this are the cancel dead zone.
pub const INNER_RADIUS: f64 = 26.0;
/// Pointer distances beyond this are outside the wheel and cancel.
pub const OUTER_RADIUS: f64 = 110.0;
/// Distance from the center to each slot's center.
pub const SLOT_RADIUS: f64 = 76.0;
pub const SLOT_SIZE: f64 = 50.0;
pub const HUB_SIZE: f64 = 44.0;
/// How much a slot grows while hovered.
pub const HOVER_SCALE: f64 = 1.12;
/// Space below the disc reserved for the name label.
pub const LABEL_GAP: f64 = 10.0;
pub const LABEL_HEIGHT: f64 = 28.0;

pub const DISC_SIZE: Size = Size::new(OUTER_RADIUS * 2.0, OUTER_RADIUS * 2.0);
pub const SIZE: Size = Size::new(OUTER_RADIUS * 2.0, OUTER_RADIUS * 2.0 + LABEL_GAP + LABEL_HEIGHT);

/// Angle covered by one of `count` slots.
pub fn sweep(count: usize) -> f64 {
    2.0 * PI / count as f64
}

/// Angle of a slot's center, measured clockwise from the positive x axis.
pub fn slot_angle(index: usize, count: usize) -> f64 {
    -PI / 2.0 + index as f64 * sweep(count)
}

pub fn slot_center(index: usize, count: usize) -> Point {
    let angle = slot_angle(index, count);
    Point::new(angle.cos(), angle.sin()) * SLOT_RADIUS
}

/// The slot under `offset` from the wheel center, or `None` in the dead zone and outside the disc.
pub fn slot_at(offset: Point, count: usize) -> Option<usize> {
    if count == 0 {
        return None;
    }
    let distance = offset.length();
    if !(INNER_RADIUS..=OUTER_RADIUS).contains(&distance) {
        return None;
    }
    let step = sweep(count);
    let direction = offset.y.atan2(offset.x);
    let from_top = (direction + PI / 2.0 + step / 2.0).rem_euclid(2.0 * PI);
    Some((from_top / step) as usize % count)
}

fn clamp_axis(value: f64, before: f64, after: f64, extent: f64, margin: f64) -> f64 {
    let min = before + margin;
    let max = extent - after - margin;
    if min > max { extent / 2.0 } else { value.clamp(min, max) }
}

/// Keeps the whole wheel and its label inside `viewport`, when it fits.
pub fn clamp_center(pointer: Point, viewport: Size, margin: f64) -> Point {
    Point::new(
        clamp_axis(pointer.x, OUTER_RADIUS, OUTER_RADIUS, viewport.width, margin),
        clamp_axis(pointer.y, OUTER_RADIUS, SIZE.height - OUTER_RADIUS, viewport.height, margin),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    const RING: f64 = SLOT_RADIUS;

    #[test]
    fn slots_start_at_twelve_oclock_and_run_clockwise() {
        assert_eq!(slot_at(Point::new(0.0, -RING), 4), Some(0));
        assert_eq!(slot_at(Point::new(RING, 0.0), 4), Some(1));
        assert_eq!(slot_at(Point::new(0.0, RING), 4), Some(2));
        assert_eq!(slot_at(Point::new(-RING, 0.0), 4), Some(3));
        for index in 0..7 {
            assert_eq!(slot_at(slot_center(index, 7), 7), Some(index));
        }
    }

    #[test]
    fn a_slot_owns_its_whole_slice_not_just_the_tile() {
        // 40 degrees clockwise from the top is still inside slot 0's 90 degree slice.
        assert_eq!(slot_at(Point::new(40.0, -50.0), 4), Some(0));
        assert_eq!(slot_at(Point::new(50.0, -40.0), 4), Some(1));
    }

    #[test]
    fn the_dead_zone_and_outside_the_disc_select_nothing() {
        assert_eq!(slot_at(Point::ZERO, 7), None);
        assert_eq!(slot_at(Point::new(0.0, -20.0), 7), None);
        assert_eq!(slot_at(Point::new(0.0, -130.0), 7), None);
        assert_eq!(slot_at(Point::new(0.0, -RING), 0), None);
    }

    #[test]
    fn clamp_center_keeps_the_wheel_and_label_on_screen() {
        let viewport = Size::new(800.0, 600.0);
        assert_eq!(clamp_center(Point::new(400.0, 300.0), viewport, 8.0), Point::new(400.0, 300.0));
        let corner = clamp_center(Point::ZERO, viewport, 8.0);
        assert!(corner.x - OUTER_RADIUS >= 0.0);
        assert!(corner.y - OUTER_RADIUS >= 0.0);
        let bottom = clamp_center(Point::new(400.0, 600.0), viewport, 8.0);
        assert!(bottom.y - OUTER_RADIUS + SIZE.height <= 600.0);
    }
}

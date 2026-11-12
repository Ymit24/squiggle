//! Geometry helpers shared by feature kinds and tools (`feature_geometry.dart`).

use crate::geom::{Point, Rect};
use std::f64::consts::PI;

/// Extra world-space tolerance when hit-testing polyline segments.
pub const POLYLINE_HIT_SLOP: f64 = 4.0;

/// Minimum envelope dimension so degenerate lines still expose resize handles.
pub const MIN_ENVELOPE_DIMENSION: f64 = 1.0;

pub fn world_points(origin: Point, local_points: &[Point]) -> Vec<Point> {
    local_points.iter().map(|p| origin + *p).collect()
}

/// Points relative to `reference`; the first is forced to zero like the Dart original.
pub fn local_points_from_world(world: &[Point], reference: Point) -> Vec<Point> {
    if world.is_empty() {
        return Vec::new();
    }
    std::iter::once(Point::ZERO).chain(world[1..].iter().map(|p| *p - reference)).collect()
}

pub fn envelope_of_points(world: &[Point], stroke_padding: f64) -> Rect {
    let Some(first) = world.first() else {
        return Rect::from_ltwh(0.0, 0.0, MIN_ENVELOPE_DIMENSION, MIN_ENVELOPE_DIMENSION);
    };
    let (mut min_x, mut max_x, mut min_y, mut max_y) = (first.x, first.x, first.y, first.y);
    for p in &world[1..] {
        min_x = min_x.min(p.x);
        max_x = max_x.max(p.x);
        min_y = min_y.min(p.y);
        max_y = max_y.max(p.y);
    }
    let envelope = Rect::from_ltrb(min_x, min_y, max_x, max_y).inflate(stroke_padding);
    Rect::from_ltwh(
        envelope.left,
        envelope.top,
        envelope.width().max(MIN_ENVELOPE_DIMENSION),
        envelope.height().max(MIN_ENVELOPE_DIMENSION),
    )
}

pub fn distance_to_segment(point: Point, start: Point, end: Point) -> f64 {
    let ab = end - start;
    let len_sq = ab.x * ab.x + ab.y * ab.y;
    if len_sq == 0.0 {
        return point.distance(start);
    }
    let t = (((point.x - start.x) * ab.x + (point.y - start.y) * ab.y) / len_sq).clamp(0.0, 1.0);
    point.distance(Point::new(start.x + ab.x * t, start.y + ab.y * t))
}

pub fn segment_intersects_rect(start: Point, end: Point, rect: &Rect) -> bool {
    if rect.contains(start) || rect.contains(end) {
        return true;
    }
    let (tl, tr, br, bl) = (rect.top_left(), rect.top_right(), rect.bottom_right(), rect.bottom_left());
    segments_intersect(start, end, tl, tr)
        || segments_intersect(start, end, tr, br)
        || segments_intersect(start, end, br, bl)
        || segments_intersect(start, end, bl, tl)
}

pub fn segments_intersect(a1: Point, a2: Point, b1: Point, b2: Point) -> bool {
    let d1 = direction(b1, b2, a1);
    let d2 = direction(b1, b2, a2);
    let d3 = direction(a1, a2, b1);
    let d4 = direction(a1, a2, b2);
    if ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) && ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0)) {
        return true;
    }
    (d1 == 0.0 && on_segment(b1, b2, a1))
        || (d2 == 0.0 && on_segment(b1, b2, a2))
        || (d3 == 0.0 && on_segment(a1, a2, b1))
        || (d4 == 0.0 && on_segment(a1, a2, b2))
}

pub fn direction(start: Point, end: Point, point: Point) -> f64 {
    (point.x - start.x) * (end.y - start.y) - (end.x - start.x) * (point.y - start.y)
}

pub fn on_segment(start: Point, end: Point, point: Point) -> bool {
    point.x <= start.x.max(end.x)
        && point.x >= start.x.min(end.x)
        && point.y <= start.y.max(end.y)
        && point.y >= start.y.min(end.y)
}

/// Rect that expands symmetrically from `center` to `point`.
pub fn center_rect_from_points(center: Point, point: Point) -> Rect {
    Rect::from_center(center, (point.x - center.x).abs() * 2.0, (point.y - center.y).abs() * 2.0)
}

/// Square rect that expands symmetrically from `center` to `point`.
pub fn square_center_rect_from_points(center: Point, point: Point) -> Rect {
    symmetric_rect_with_aspect_ratio(center, point, 1.0, true, true)
}

/// Dart's `double.sign` as used for drag directions (zero maps to +1 at call sites).
fn sign_or_one(v: f64) -> f64 {
    if v == 0.0 { 1.0 } else { v.signum() }
}

/// Square rect from two opposite corners.
pub fn square_rect_from_points(start: Point, end: Point) -> Rect {
    let (dx, dy) = (end.x - start.x, end.y - start.y);
    let side = dx.abs().max(dy.abs());
    Rect::from_points(start, Point::new(start.x + side * sign_or_one(dx), start.y + side * sign_or_one(dy)))
}

/// Snaps `point` to the nearest 45 degree ray from `origin`, preserving distance.
pub fn snap_point_to_45_degree_angle(origin: Point, point: Point) -> Point {
    let (dx, dy) = (point.x - origin.x, point.y - origin.y);
    let distance = dx.hypot(dy);
    if distance == 0.0 {
        return point;
    }
    let increment = PI / 4.0;
    let snapped = (dy.atan2(dx) / increment).round() * increment;
    Point::new(origin.x + snapped.cos() * distance, origin.y + snapped.sin() * distance)
}

/// Locks movement to the horizontal or vertical axis relative to `drag_start`.
pub fn constrain_move_to_axis(drag_start: Point, current: Point) -> Point {
    let (dx, dy) = (current.x - drag_start.x, current.y - drag_start.y);
    if dx.abs() >= dy.abs() {
        Point::new(current.x, drag_start.y)
    } else {
        Point::new(drag_start.x, current.y)
    }
}

/// Movement from `drag_start`, optionally locked to one axis.
pub fn constrained_move_delta(drag_start: Point, current: Point, constrain_to_axis: bool) -> Point {
    let target = if constrain_to_axis { constrain_move_to_axis(drag_start, current) } else { current };
    target - drag_start
}

/// Corner resize with a fixed `anchor` and locked width/height ratio.
pub fn rect_from_anchor_with_aspect_ratio(anchor: Point, dragged: Point, aspect_ratio: f64) -> Rect {
    if aspect_ratio <= 0.0 {
        return Rect::from_points(anchor, dragged);
    }
    let (dx, dy) = (dragged.x - anchor.x, dragged.y - anchor.y);
    if dx == 0.0 && dy == 0.0 {
        return Rect::from_points(anchor, dragged);
    }
    let (abs_dx, abs_dy) = (dx.abs(), dy.abs());
    let effective = if abs_dy == 0.0 { f64::INFINITY } else { abs_dx / abs_dy };
    let (width, height) = if effective > aspect_ratio {
        (abs_dx, abs_dx / aspect_ratio)
    } else {
        (abs_dy * aspect_ratio, abs_dy)
    };
    Rect::from_points(anchor, Point::new(anchor.x + width * sign_or_one(dx), anchor.y + height * sign_or_one(dy)))
}

/// Which edge(s) an edge-resize drags.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct ResizeEdges {
    pub top: bool,
    pub bottom: bool,
    pub left: bool,
    pub right: bool,
}

/// Edge resize with aspect ratio locked; the opposite edge stays fixed.
pub fn edge_resize_with_aspect_ratio(bounds: Rect, dragged: Point, edges: ResizeEdges, aspect_ratio: f64) -> Rect {
    if aspect_ratio <= 0.0 {
        return bounds;
    }
    if edges.top || edges.bottom {
        let fixed_y = if edges.top { bounds.bottom } else { bounds.top };
        let height = (dragged.y - fixed_y).abs();
        let width = height * aspect_ratio;
        let top = fixed_y.min(dragged.y);
        return Rect::from_ltwh(bounds.center().x - width / 2.0, top, width, height);
    }
    let fixed_x = if edges.left { bounds.right } else { bounds.left };
    let width = (dragged.x - fixed_x).abs();
    let height = width / aspect_ratio;
    Rect::from_ltwh(fixed_x.min(dragged.x), bounds.center().y - height / 2.0, width, height)
}

/// Symmetric resize from `center` with aspect ratio locked.
pub fn symmetric_rect_with_aspect_ratio(
    center: Point,
    dragged: Point,
    aspect_ratio: f64,
    resize_horizontal: bool,
    resize_vertical: bool,
) -> Rect {
    if aspect_ratio <= 0.0 {
        return Rect::from_center(center, 0.0, 0.0);
    }
    if resize_horizontal && resize_vertical {
        return symmetric_corner_bounds(center, dragged, aspect_ratio);
    }
    if resize_vertical {
        let height = (dragged.y - center.y).abs() * 2.0;
        return Rect::from_center(center, height * aspect_ratio, height);
    }
    let width = (dragged.x - center.x).abs() * 2.0;
    Rect::from_center(center, width, width / aspect_ratio)
}

fn symmetric_corner_bounds(center: Point, dragged: Point, aspect_ratio: f64) -> Rect {
    let half_width = (dragged.x - center.x).abs();
    let half_height = (dragged.y - center.y).abs();
    let effective = if half_height == 0.0 { f64::INFINITY } else { half_width / half_height };
    if effective > aspect_ratio {
        let width = half_width * 2.0;
        return Rect::from_center(center, width, width / aspect_ratio);
    }
    let height = half_height * 2.0;
    Rect::from_center(center, height * aspect_ratio, height)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn p(x: f64, y: f64) -> Point {
        Point::new(x, y)
    }

    fn close(a: f64, b: f64) {
        assert!((a - b).abs() < 1e-3, "{a} != {b}");
    }

    #[test]
    fn center_rect_expands_symmetrically() {
        assert_eq!(center_rect_from_points(p(50.0, 50.0), p(100.0, 80.0)), Rect::from_ltwh(0.0, 20.0, 100.0, 60.0));
        assert_eq!(center_rect_from_points(p(50.0, 50.0), p(20.0, 30.0)), Rect::from_ltwh(20.0, 30.0, 60.0, 40.0));
    }

    #[test]
    fn square_center_rect_uses_larger_axis() {
        assert_eq!(
            square_center_rect_from_points(p(50.0, 50.0), p(100.0, 80.0)),
            Rect::from_ltwh(0.0, 0.0, 100.0, 100.0)
        );
    }

    #[test]
    fn square_rect_from_points_uses_larger_axis_and_direction() {
        assert_eq!(square_rect_from_points(p(0.0, 0.0), p(100.0, 50.0)), Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
        assert_eq!(square_rect_from_points(p(100.0, 100.0), p(0.0, 50.0)), Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
    }

    #[test]
    fn snap_to_45_degrees() {
        let point = p(100.0, 10.0);
        let snapped = snap_point_to_45_degree_angle(Point::ZERO, point);
        close(snapped.y, 0.0);
        close(snapped.length(), point.length());

        let point = p(100.0, 90.0);
        let snapped = snap_point_to_45_degree_angle(Point::ZERO, point);
        close(snapped.x, snapped.y);
        close(snapped.length(), point.length());

        let point = p(70.0, 70.0);
        close(snap_point_to_45_degree_angle(Point::ZERO, point).length(), point.length());
    }

    #[test]
    fn constrain_move_to_axis_locks_dominant_axis() {
        assert_eq!(constrain_move_to_axis(p(0.0, 0.0), p(50.0, 10.0)), p(50.0, 0.0));
        assert_eq!(constrain_move_to_axis(p(0.0, 0.0), p(10.0, 50.0)), p(0.0, 50.0));
    }

    #[test]
    fn constrained_move_delta_cases() {
        assert_eq!(constrained_move_delta(p(10.0, 20.0), p(40.0, 60.0), false), p(30.0, 40.0));
        assert_eq!(constrained_move_delta(p(10.0, 20.0), p(40.0, 30.0), true), p(30.0, 0.0));
    }

    #[test]
    fn anchor_resize_locks_ratio() {
        let rect = rect_from_anchor_with_aspect_ratio(p(0.0, 0.0), p(200.0, 100.0), 2.0);
        close(rect.width(), 200.0);
        close(rect.height(), 100.0);
    }

    #[test]
    fn edge_resize_expands_width_symmetrically() {
        let edges = ResizeEdges { bottom: true, ..Default::default() };
        let rect = edge_resize_with_aspect_ratio(Rect::from_ltwh(0.0, 0.0, 100.0, 100.0), p(50.0, 150.0), edges, 1.0);
        close(rect.width(), 150.0);
        close(rect.height(), 150.0);
        close(rect.top, 0.0);
    }

    #[test]
    fn symmetric_corner_resize_is_locked() {
        let rect = symmetric_rect_with_aspect_ratio(p(50.0, 50.0), p(150.0, 120.0), 1.0, true, true);
        close(rect.width(), rect.height());
    }

    #[test]
    fn distance_to_segment_is_perpendicular() {
        assert_eq!(distance_to_segment(p(50.0, 10.0), Point::ZERO, p(100.0, 0.0)), 10.0);
    }

    #[test]
    fn envelope_enforces_minimum_dimension() {
        let envelope = envelope_of_points(&[p(0.0, 5.0), p(100.0, 5.0)], 4.0);
        assert_eq!(envelope.width(), 108.0);
        assert!(envelope.height() >= MIN_ENVELOPE_DIMENSION);
        assert_eq!(envelope_of_points(&[], 4.0).width(), MIN_ENVELOPE_DIMENSION);
    }

    #[test]
    fn segment_rect_intersection() {
        let rect = Rect::from_ltwh(40.0, -5.0, 20.0, 10.0);
        assert!(segment_intersects_rect(p(0.0, 0.0), p(100.0, 0.0), &rect));
        assert!(!segment_intersects_rect(p(0.0, 0.0), p(100.0, 0.0), &Rect::from_ltwh(10.0, 50.0, 20.0, 20.0)));
    }
}

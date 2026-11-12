//! Display-list painting helpers (ports of `fill_painter`, `stroke_painter`, `text_painter`).
//!
//! Dart paints `Path`s; here shapes are flattened to [`Contour`]s up front, and the helpers
//! expand dashes, dots and hatching into plain [`Painter`] strokes and fills.

pub mod fill;
pub mod stroke;
pub mod text;

use crate::geom::{Point, Rect};
use std::f64::consts::TAU;

pub use fill::paint_fill;
pub use stroke::paint_stroke;
pub use text::{
    MAX_TEXT_FONT_SIZE, MIN_TEXT_FONT_SIZE, measure_text_intrinsic, measure_text_wrapped, paint_text,
};

/// Segments used to approximate ellipses.
pub const ELLIPSE_SEGMENTS: usize = 64;

/// A flattened path: a polyline that is optionally closed back to its first point.
#[derive(Clone, Debug, PartialEq)]
pub struct Contour {
    pub points: Vec<Point>,
    pub closed: bool,
}

impl Contour {
    pub fn open(points: Vec<Point>) -> Self {
        Contour { points, closed: false }
    }

    pub fn closed(points: Vec<Point>) -> Self {
        Contour { points, closed: true }
    }

    /// Rectangle outline starting at the top-left and running clockwise on screen.
    pub fn rect(rect: Rect) -> Self {
        Contour::closed(vec![rect.top_left(), rect.top_right(), rect.bottom_right(), rect.bottom_left()])
    }

    /// Ellipse inscribed in `rect`, starting at its right-most point and running clockwise
    /// on screen, approximated with [`ELLIPSE_SEGMENTS`] segments.
    pub fn ellipse(rect: Rect) -> Self {
        let (c, rx, ry) = (rect.center(), rect.width() / 2.0, rect.height() / 2.0);
        let points = (0..ELLIPSE_SEGMENTS)
            .map(|i| {
                let a = TAU * i as f64 / ELLIPSE_SEGMENTS as f64;
                Point::new(c.x + rx * a.cos(), c.y + ry * a.sin())
            })
            .collect();
        Contour::closed(points)
    }

    /// Vertices including the closing point for closed contours.
    pub(crate) fn vertices(&self) -> Vec<Point> {
        let mut v = self.points.clone();
        if self.closed && let Some(first) = v.first().copied() {
            v.push(first);
        }
        v
    }

    pub fn bounds(&self) -> Rect {
        let Some(first) = self.points.first() else { return Rect::ZERO };
        self.points[1..].iter().fold(Rect::from_ltrb(first.x, first.y, first.x, first.y), |r, p| {
            Rect::from_ltrb(r.left.min(p.x), r.top.min(p.y), r.right.max(p.x), r.bottom.max(p.y))
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rect_contour_is_closed_clockwise() {
        let c = Contour::rect(Rect::from_ltwh(0.0, 0.0, 10.0, 5.0));
        assert!(c.closed);
        assert_eq!(c.points[1], Point::new(10.0, 0.0));
        assert_eq!(c.vertices().len(), 5);
    }

    #[test]
    fn ellipse_touches_extremes() {
        let c = Contour::ellipse(Rect::from_ltwh(0.0, 0.0, 20.0, 10.0));
        assert_eq!(c.points.len(), ELLIPSE_SEGMENTS);
        let b = c.bounds();
        assert!((b.left - 0.0).abs() < 1e-9 && (b.right - 20.0).abs() < 1e-9);
        assert!((b.top - 0.0).abs() < 1e-9 && (b.bottom - 10.0).abs() < 1e-9);
    }
}

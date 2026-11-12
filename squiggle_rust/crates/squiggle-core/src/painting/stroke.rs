//! Stroke painting with dashed and dotted patterns (`stroke_painter.dart`).

use super::Contour;
use crate::color::Color;
use crate::geom::Point;
use crate::paint::{Cap, Painter};
use crate::stroke_type::StrokeType;
use std::f64::consts::TAU;

const DOT_SEGMENTS: usize = 16;

/// Strokes `contours`; dashed and dotted types are expanded into short strokes and dot polygons.
pub fn paint_stroke(
    painter: &mut Painter,
    contours: &[Contour],
    width: f64,
    color: Color,
    cap: Cap,
    stroke_type: StrokeType,
) {
    if color.a() == 0 {
        return;
    }
    for contour in contours {
        if stroke_type == StrokeType::Solid || width <= 0.0 {
            painter.stroke(&contour.points, contour.closed, width, color, cap);
        } else {
            paint_patterned(painter, contour, width, color, cap, stroke_type);
        }
    }
}

fn paint_patterned(
    painter: &mut Painter,
    contour: &Contour,
    width: f64,
    color: Color,
    cap: Cap,
    stroke_type: StrokeType,
) {
    let path = Measured::new(contour.vertices());
    if path.length == 0.0 {
        return;
    }
    let dashed = stroke_type == StrokeType::Dashed;
    let spacing = width * if dashed { 6.0 } else { 3.0 };
    // Fit whole repeats around closed outlines to avoid overlapping at the seam.
    let count = if contour.closed {
        (path.length / spacing).round().max(1.0)
    } else {
        (path.length / spacing).ceil().max(1.0)
    } as usize;
    let step = if contour.closed { path.length / count as f64 } else { spacing };
    for i in 0..count {
        let distance = i as f64 * step;
        if dashed {
            let piece = path.extract(distance, (distance + step * 2.0 / 3.0).min(path.length));
            painter.stroke(&piece, false, width, color, cap);
        } else {
            painter.fill(&dot(path.point_at(distance), width / 2.0), color);
        }
    }
}

fn dot(center: Point, radius: f64) -> Vec<Point> {
    (0..DOT_SEGMENTS)
        .map(|i| {
            let a = TAU * i as f64 / DOT_SEGMENTS as f64;
            Point::new(center.x + radius * a.cos(), center.y + radius * a.sin())
        })
        .collect()
}

/// A polyline with cumulative arc lengths, like Dart's `PathMetric`.
struct Measured {
    points: Vec<Point>,
    cumulative: Vec<f64>,
    length: f64,
}

impl Measured {
    fn new(points: Vec<Point>) -> Self {
        let mut cumulative = vec![0.0];
        for pair in points.windows(2) {
            cumulative.push(cumulative.last().copied().unwrap_or(0.0) + pair[0].distance(pair[1]));
        }
        let length = cumulative.last().copied().unwrap_or(0.0);
        Measured { points, cumulative, length }
    }

    fn point_at(&self, distance: f64) -> Point {
        let d = distance.clamp(0.0, self.length);
        let i = self.cumulative.partition_point(|c| *c <= d).clamp(1, self.points.len() - 1);
        let (a, b) = (self.points[i - 1], self.points[i]);
        let span = self.cumulative[i] - self.cumulative[i - 1];
        if span == 0.0 { a } else { a + (b - a) * ((d - self.cumulative[i - 1]) / span) }
    }

    fn extract(&self, from: f64, to: f64) -> Vec<Point> {
        let mut out = vec![self.point_at(from)];
        for (p, c) in self.points.iter().zip(&self.cumulative) {
            if *c > from && *c < to {
                out.push(*p);
            }
        }
        out.push(self.point_at(to));
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::geom::Rect;
    use crate::paint::DrawCmd;

    fn line(len: f64) -> Contour {
        Contour::open(vec![Point::new(0.0, 0.0), Point::new(len, 0.0)])
    }

    fn run(contour: Contour, width: f64, t: StrokeType) -> Vec<DrawCmd> {
        let mut painter = Painter::new();
        paint_stroke(&mut painter, &[contour], width, Color::WHITE, Cap::Butt, t);
        painter.commands
    }

    #[test]
    fn solid_emits_a_single_stroke() {
        let cmds = run(line(100.0), 4.0, StrokeType::Solid);
        assert_eq!(cmds.len(), 1);
        assert!(matches!(&cmds[0], DrawCmd::Stroke { closed: false, width, .. } if *width == 4.0));
    }

    #[test]
    fn dashed_open_line_repeats_every_six_widths() {
        // spacing 24 -> ceil(100 / 24) = 5 dashes, each 2/3 of the spacing long.
        let cmds = run(line(100.0), 4.0, StrokeType::Dashed);
        assert_eq!(cmds.len(), 5);
        let DrawCmd::Stroke { points, .. } = &cmds[1] else { panic!("expected stroke") };
        assert_eq!(points.first().map(|p| p.x), Some(24.0));
        assert_eq!(points.last().map(|p| p.x), Some(40.0));
        let DrawCmd::Stroke { points, .. } = &cmds[4] else { panic!("expected stroke") };
        assert_eq!(points.last().map(|p| p.x), Some(100.0));
    }

    #[test]
    fn dotted_emits_filled_dots_on_the_line() {
        // spacing 12 -> ceil(100 / 12) = 9 dots.
        let cmds = run(line(100.0), 4.0, StrokeType::Dotted);
        assert_eq!(cmds.len(), 9);
        assert!(cmds.iter().all(|c| matches!(c, DrawCmd::Fill { .. })));
    }

    #[test]
    fn closed_outline_fits_whole_repeats() {
        let rect = Contour::rect(Rect::from_ltwh(0.0, 0.0, 100.0, 50.0));
        // perimeter 300, spacing 24 -> round(12.5) = 13 dashes.
        assert_eq!(run(rect, 4.0, StrokeType::Dashed).len(), 13);
    }

    #[test]
    fn dashes_follow_corners() {
        let path = Contour::open(vec![Point::new(0.0, 0.0), Point::new(6.0, 0.0), Point::new(6.0, 10.0)]);
        // spacing 12, dash length 8: the first dash turns the corner at distance 6.
        let cmds = run(path, 2.0, StrokeType::Dashed);
        let DrawCmd::Stroke { points, .. } = &cmds[0] else { panic!("expected stroke") };
        assert_eq!(points, &[Point::new(0.0, 0.0), Point::new(6.0, 0.0), Point::new(6.0, 2.0)]);
    }

    #[test]
    fn transparent_strokes_emit_nothing() {
        let mut painter = Painter::new();
        paint_stroke(&mut painter, &[line(10.0)], 4.0, Color::TRANSPARENT, Cap::Butt, StrokeType::Solid);
        assert!(painter.commands.is_empty());
    }
}

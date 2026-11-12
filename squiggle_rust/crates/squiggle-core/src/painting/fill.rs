//! Fill painting with hatched variants (`fill_painter.dart`).

use super::Contour;
use crate::color::Color;
use crate::fill_type::FillType;
use crate::geom::Point;
use crate::paint::{Cap, Painter};

pub const HATCH_SPACING: f64 = 12.0;
pub const HATCH_LINE_WIDTH: f64 = 1.5;

/// Fills the closed `contours`. Solid fills emit polygons; `Lines` and `Crosshatch` emit diagonal
/// strokes clipped to the shape (even-odd across all contours).
pub fn paint_fill(painter: &mut Painter, contours: &[Contour], color: Color, fill_type: FillType) {
    if color.a() == 0 {
        return;
    }
    if fill_type == FillType::Solid {
        for contour in contours {
            painter.fill(&contour.points, color);
        }
        return;
    }
    paint_hatch(painter, contours, color, fill_type == FillType::Crosshatch);
}

fn paint_hatch(painter: &mut Painter, contours: &[Contour], color: Color, cross: bool) {
    let Some(bounds) = contours.iter().filter(|c| !c.points.is_empty()).map(Contour::bounds).reduce(|a, b| a.expand_to_include(&b))
    else {
        return;
    };
    if bounds.is_empty() {
        return;
    }
    let height = bounds.height();
    let mut x = -height;
    while x < bounds.width() {
        let ascending = (Point::new(bounds.left + x, bounds.bottom), Point::new(bounds.left + x + height, bounds.top));
        hatch_line(painter, contours, ascending, color);
        if cross {
            let descending = (Point::new(bounds.left + x, bounds.top), Point::new(bounds.left + x + height, bounds.bottom));
            hatch_line(painter, contours, descending, color);
        }
        x += HATCH_SPACING;
    }
}

/// Draws the parts of the segment `a -> b` that lie inside the shape.
fn hatch_line(painter: &mut Painter, contours: &[Contour], (a, b): (Point, Point), color: Color) {
    let mut ts: Vec<f64> = contours.iter().flat_map(|c| crossings(c, a, b)).collect();
    ts.sort_by(f64::total_cmp);
    for pair in ts.chunks_exact(2) {
        let (start, end) = (a + (b - a) * pair[0], a + (b - a) * pair[1]);
        if pair[1] > pair[0] {
            painter.stroke(&[start, end], false, HATCH_LINE_WIDTH, color, Cap::Butt);
        }
    }
}

/// Parameters along the infinite line `a -> b` where the contour's edges cross it. Uses the
/// half-open "which side" rule so shared vertices count once.
fn crossings(contour: &Contour, a: Point, b: Point) -> Vec<f64> {
    let d = b - a;
    let len_sq = d.x * d.x + d.y * d.y;
    let side = |p: Point| d.x * (p.y - a.y) - d.y * (p.x - a.x);
    let n = contour.points.len();
    let mut out = Vec::new();
    for i in 0..n {
        let (p, q) = (contour.points[i], contour.points[(i + 1) % n]);
        let (sp, sq) = (side(p), side(q));
        if (sp > 0.0) == (sq > 0.0) {
            continue;
        }
        let hit = p + (q - p) * (sp / (sp - sq));
        out.push(((hit.x - a.x) * d.x + (hit.y - a.y) * d.y) / len_sq);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::geom::Rect;
    use crate::paint::DrawCmd;

    fn run(rect: Rect, t: FillType) -> Vec<DrawCmd> {
        let mut painter = Painter::new();
        paint_fill(&mut painter, &[Contour::rect(rect)], Color::WHITE, t);
        painter.commands
    }

    #[test]
    fn solid_emits_one_polygon() {
        let cmds = run(Rect::from_ltwh(0.0, 0.0, 50.0, 30.0), FillType::Solid);
        assert!(matches!(&cmds[..], [DrawCmd::Fill { points, .. }] if points.len() == 4));
    }

    #[test]
    fn transparent_fill_emits_nothing() {
        let mut painter = Painter::new();
        let contour = Contour::rect(Rect::from_ltwh(0.0, 0.0, 50.0, 30.0));
        paint_fill(&mut painter, &[contour], Color::TRANSPARENT, FillType::Lines);
        assert!(painter.commands.is_empty());
    }

    #[test]
    fn lines_are_diagonal_strokes_inside_the_shape() {
        let rect = Rect::from_ltwh(10.0, 10.0, 50.0, 30.0);
        let cmds = run(rect, FillType::Lines);
        assert!(!cmds.is_empty());
        for cmd in &cmds {
            let DrawCmd::Stroke { points, width, .. } = cmd else { panic!("expected stroke") };
            assert_eq!(*width, HATCH_LINE_WIDTH);
            for p in points {
                assert!(p.x >= rect.left - 1e-9 && p.x <= rect.right + 1e-9, "{p:?}");
                assert!(p.y >= rect.top - 1e-9 && p.y <= rect.bottom + 1e-9, "{p:?}");
            }
            // Ascending diagonal: x grows while y shrinks.
            assert!(points[1].x > points[0].x && points[1].y < points[0].y);
        }
    }

    #[test]
    fn crosshatch_doubles_the_lines() {
        let rect = Rect::from_ltwh(0.0, 0.0, 60.0, 40.0);
        assert_eq!(run(rect, FillType::Crosshatch).len(), 2 * run(rect, FillType::Lines).len());
    }

    #[test]
    fn empty_bounds_paint_nothing() {
        assert!(run(Rect::from_ltwh(0.0, 0.0, 0.0, 30.0), FillType::Lines).is_empty());
    }
}

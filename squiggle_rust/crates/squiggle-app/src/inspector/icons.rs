//! Small drawn icons for swatches. Material icons are approximated with a few strokes on a
//! 16x16 grid; previews of strokes and fills reuse the core painters like the Dart painters do.

use super::style_swatch::INNER;
use crate::render;
use rune::{Color, El, LineCap, Shape, canvas};
use squiggle_core::camera::Camera;
use squiggle_core::color::Color as CoreColor;
use squiggle_core::fill_type::FillType;
use squiggle_core::geom::{Point, Rect};
use squiggle_core::paint::{Cap, Painter};
use squiggle_core::painting::{Contour, paint_fill, paint_stroke};
use squiggle_core::stroke_type::StrokeType;

/// One straight stroke: `[x1, y1, x2, y2, width]` on the 16x16 grid.
pub type Seg = [f32; 5];

const GRID: f32 = 16.0;

/// Strokes `segs` scaled to `size` points square.
pub fn glyph(segs: &[Seg], size: f32, color: Color) -> El {
    let k = size / GRID;
    let shape = segs.iter().fold(Shape::new().view_box(size, size), |shape, s| {
        shape.line([s[0] * k, s[1] * k], [s[2] * k, s[3] * k], s[4] * k, LineCap::Butt, color)
    });
    canvas(shape).size(size, size)
}

/// Adds a round-capped polyline given on the 16x16 grid.
fn poly(shape: Shape, points: &[[f32; 2]], size: f32, width: f32, color: Color) -> Shape {
    let k = size / GRID;
    let pts: Vec<[f32; 2]> = points.iter().map(|p| [p[0] * k, p[1] * k]).collect();
    shape.stroke_with(pts, false, width, LineCap::Round, color)
}

pub fn align_left(color: Color) -> El {
    glyph(&[[2.0, 2.0, 2.0, 14.0, 1.5], [4.0, 5.0, 14.0, 5.0, 4.0], [4.0, 11.0, 9.0, 11.0, 4.0]], 14.0, color)
}
pub fn align_center_horizontal(color: Color) -> El {
    glyph(&[[8.0, 2.0, 8.0, 14.0, 1.5], [3.0, 5.0, 13.0, 5.0, 4.0], [5.0, 11.0, 11.0, 11.0, 4.0]], 14.0, color)
}
pub fn align_right(color: Color) -> El {
    glyph(&[[14.0, 2.0, 14.0, 14.0, 1.5], [2.0, 5.0, 12.0, 5.0, 4.0], [7.0, 11.0, 12.0, 11.0, 4.0]], 14.0, color)
}
pub fn align_top(color: Color) -> El {
    glyph(&[[2.0, 2.0, 14.0, 2.0, 1.5], [5.0, 4.0, 5.0, 14.0, 4.0], [11.0, 4.0, 11.0, 9.0, 4.0]], 14.0, color)
}
pub fn align_center_vertical(color: Color) -> El {
    glyph(&[[2.0, 8.0, 14.0, 8.0, 1.5], [5.0, 2.0, 5.0, 14.0, 4.0], [11.0, 5.0, 11.0, 11.0, 4.0]], 14.0, color)
}
pub fn align_bottom(color: Color) -> El {
    glyph(&[[2.0, 14.0, 14.0, 14.0, 1.5], [5.0, 2.0, 5.0, 12.0, 4.0], [11.0, 7.0, 11.0, 12.0, 4.0]], 14.0, color)
}
pub fn distribute_horizontal(color: Color) -> El {
    glyph(&[[2.0, 2.0, 2.0, 14.0, 1.5], [14.0, 2.0, 14.0, 14.0, 1.5], [8.0, 4.0, 8.0, 12.0, 4.0]], 14.0, color)
}
pub fn distribute_vertical(color: Color) -> El {
    glyph(&[[2.0, 2.0, 14.0, 2.0, 1.5], [2.0, 14.0, 14.0, 14.0, 1.5], [4.0, 8.0, 12.0, 8.0, 4.0]], 14.0, color)
}

/// Horizontal text alignment: four lines, flush left, centred or flush right.
pub fn text_align_horizontal(h: squiggle_core::text_alignment::TextHorizontalAlignment, color: Color) -> El {
    use squiggle_core::text_alignment::TextHorizontalAlignment as H;
    let span = |len: f32| match h {
        H::Left => (2.0, 2.0 + len),
        H::Center => (8.0 - len / 2.0, 8.0 + len / 2.0),
        H::Right => (14.0 - len, 14.0),
    };
    let segs: Vec<Seg> = [(3.0, 12.0), (6.0, 8.0), (9.0, 12.0), (12.0, 8.0)]
        .iter()
        .map(|&(y, len)| {
            let (a, b) = span(len);
            [a, y, b, y, 1.6]
        })
        .collect();
    glyph(&segs, 14.0, color)
}

/// Vertical text alignment: a rule at the edge the text sits against and a block of text.
pub fn text_align_vertical(v: squiggle_core::text_alignment::TextVerticalAlignment, color: Color) -> El {
    use squiggle_core::text_alignment::TextVerticalAlignment as V;
    let segs: &[Seg] = match v {
        V::Top => &[[2.0, 2.0, 14.0, 2.0, 1.5], [8.0, 5.0, 8.0, 14.0, 4.0]],
        V::Center => &[[2.0, 8.0, 14.0, 8.0, 1.5], [8.0, 3.0, 8.0, 13.0, 4.0]],
        V::Bottom => &[[2.0, 14.0, 14.0, 14.0, 1.5], [8.0, 2.0, 8.0, 11.0, 4.0]],
    };
    glyph(segs, 14.0, color)
}

/// Line end cap: a plain rounded end, or an arrowhead pointing back at the start / on at the end.
pub fn end_cap(arrow: bool, is_start: bool, color: Color) -> El {
    let size = 16.0;
    let (from, to) = if is_start { (14.0, 2.0) } else { (2.0, 14.0) };
    let mut shape = poly(Shape::new().view_box(size, size), &[[from, 8.0], [to, 8.0]], size, 2.0, color);
    if arrow {
        let back = if is_start { 6.0 } else { 10.0 };
        shape = poly(shape, &[[back, 4.0], [to, 8.0], [back, 12.0]], size, 2.0, color);
    }
    canvas(shape).size(size, size)
}

/// Bar of a given height centred in the swatch: the stroke width preview.
pub fn width_bar(height: f32, color: Color) -> El {
    let (w, y) = (INNER * 0.52, INNER / 2.0);
    let inset = height / 2.0;
    let x = (INNER - w) / 2.0;
    let shape = Shape::new().view_box(INNER, INNER).line([x + inset, y], [x + w - inset, y], height, LineCap::Round, color);
    canvas(shape).size(INNER, INNER)
}

fn core_color(c: Color) -> CoreColor {
    let s = |v: f32| (rune::color::srgb_encode(v).clamp(0.0, 1.0) * 255.0).round() as u8;
    CoreColor::from_argb((c.a.clamp(0.0, 1.0) * 255.0).round() as u8, s(c.r), s(c.g), s(c.b))
}

/// Paints a display list drawn by `f` (in a 1:1 world) as a swatch-sized canvas.
fn painted(zoom: f64, color: Color, f: impl FnOnce(&mut Painter, CoreColor)) -> El {
    let mut painter = Painter::new();
    f(&mut painter, core_color(color));
    let shape = render::shape(&painter.commands, &Camera::new(Point::ZERO, zoom));
    canvas(shape.view_box(INNER, INNER)).size(INNER, INNER)
}

/// A short horizontal stroke in the given pattern, as `_StrokeTypePreviewPainter`.
pub fn stroke_type_preview(stroke_type: StrokeType, color: Color) -> El {
    painted(1.0, color, |p, c| {
        let y = (INNER / 2.0) as f64;
        let line = Contour::open(vec![Point::new(INNER as f64 * 0.2, y), Point::new(INNER as f64 * 0.8, y)]);
        paint_stroke(p, &[line], 2.0, c, Cap::Round, stroke_type);
    })
}

/// A rectangle filled in the given style, as `_FillTypePreviewPainter`. The core hatch spacing
/// is fixed at 12, so the sample is painted 12/5 times larger and shrunk to the preview's 5.
pub fn fill_type_preview(fill_type: FillType, color: Color) -> El {
    let zoom = 12.0 / 5.0;
    painted(zoom, color, |p, c| {
        let s = INNER as f64 * zoom;
        let rect = Rect::from_ltwh(s * 0.2, s * 0.2, s * 0.6, s * 0.6);
        paint_fill(p, &[Contour::rect(rect)], c, fill_type);
    })
}

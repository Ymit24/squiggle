//! Toolkit-independent display list. Feature kinds and tools emit [`DrawCmd`]s in world
//! coordinates (already offset by ancestor group origins); the UI layer rasterises them.
//! Dashes, dots, hatching, ellipses etc. are expanded to polylines/polygons by the emitter,
//! so a renderer only needs strokes, polygon fills, text runs and images.

use crate::color::Color;
use crate::geom::{Point, Rect};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Cap {
    Butt,
    Round,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HAlign {
    Left,
    Center,
    Right,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum VAlign {
    Top,
    Middle,
    Bottom,
}

#[derive(Clone, Debug, PartialEq)]
pub enum DrawCmd {
    /// Open or closed polyline stroke.
    Stroke { points: Vec<Point>, closed: bool, width: f64, color: Color, cap: Cap },
    /// Simple (possibly concave) polygon fill.
    Fill { points: Vec<Point>, color: Color },
    /// Text laid out inside `rect` (wrapping at its width) with the given alignment.
    Text {
        text: String,
        rect: Rect,
        font_size: f64,
        color: Color,
        h_align: HAlign,
        v_align: VAlign,
    },
    /// Raster image identified by the id the [`ImageRepository`](crate) stores it under.
    Image { image_id: String, rect: Rect },
}

pub type DisplayList = Vec<DrawCmd>;

/// Sink for draw commands with a translation stack, used while walking the node tree.
#[derive(Default)]
pub struct Painter {
    pub commands: DisplayList,
    offset: Point,
}

impl Painter {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn offset(&self) -> Point {
        self.offset
    }

    /// Runs `f` with the origin translated by `by` (like canvas.save/translate/restore).
    pub fn translated(&mut self, by: Point, f: impl FnOnce(&mut Painter)) {
        let saved = self.offset;
        self.offset = saved + by;
        f(self);
        self.offset = saved;
    }

    pub fn stroke(&mut self, points: &[Point], closed: bool, width: f64, color: Color, cap: Cap) {
        let o = self.offset;
        self.commands.push(DrawCmd::Stroke {
            points: points.iter().map(|p| *p + o).collect(),
            closed,
            width,
            color,
            cap,
        });
    }

    pub fn fill(&mut self, points: &[Point], color: Color) {
        let o = self.offset;
        self.commands.push(DrawCmd::Fill { points: points.iter().map(|p| *p + o).collect(), color });
    }

    pub fn text(&mut self, text: &str, rect: Rect, font_size: f64, color: Color, h: HAlign, v: VAlign) {
        self.commands.push(DrawCmd::Text {
            text: text.to_owned(),
            rect: rect.shift(self.offset),
            font_size,
            color,
            h_align: h,
            v_align: v,
        });
    }

    pub fn image(&mut self, image_id: &str, rect: Rect) {
        self.commands.push(DrawCmd::Image { image_id: image_id.to_owned(), rect: rect.shift(self.offset) });
    }
}

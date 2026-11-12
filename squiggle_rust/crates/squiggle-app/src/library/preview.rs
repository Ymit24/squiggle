//! Document previews on library cards (`document_preview*.dart`): the saved document's display
//! list drawn through a camera that fits its content into the card, over a dotted background.

use crate::render;
use crate::theme;
use rune::tok::TextStyle;
use rune::{El, LineCap, Shape, canvas, el, text};
use squiggle_core::geom::{Rect, Size};
use squiggle_core::paint::DisplayList;
use squiggle_core::preview_fit::preview_camera;
use squiggle_core::repositories::DocumentStorage;
use squiggle_core::Node;

const DOT_GAP: f32 = 22.0;
const DOT_RADIUS: f32 = 1.1;
const CORNER: f32 = 10.0;

/// A document reduced to what a preview draws.
#[derive(Debug, Default)]
pub struct Preview {
    pub list: DisplayList,
    /// Union of the root nodes' bounds; `None` for an empty (or unreadable) document.
    pub bounds: Option<Rect>,
}

impl Preview {
    /// Reads and paints a stored document; empty if it cannot be read.
    pub fn load(storage: &DocumentStorage, id: &str) -> Preview {
        let Some(stored) = storage.load_document(id) else { return Preview::default() };
        let nodes = stored.document.nodes();
        let bounds = (!nodes.is_empty()).then(|| Node::local_bounds_of_nodes(nodes));
        Preview { list: stored.document.paint(), bounds }
    }

    pub fn is_empty(&self) -> bool {
        self.bounds.is_none()
    }
}

fn dots(size: (f32, f32)) -> Shape {
    let colour = theme::surface1().alpha(0.55);
    let mut shape = Shape::new();
    let mut y = DOT_GAP / 2.0;
    while y < size.1 {
        let mut x = DOT_GAP / 2.0;
        while x < size.0 {
            shape = shape.line([x, y], [x, y], DOT_RADIUS * 2.0, LineCap::Round, colour);
            x += DOT_GAP;
        }
        y += DOT_GAP;
    }
    shape
}

/// The empty-document glyph: a small bordered square in the middle of the preview.
fn empty_glyph() -> El {
    el()
        .size(44.0, 44.0)
        .radius(12.0)
        .fill(theme::surface0())
        .border(1.0, theme::surface1())
        .center()
        .child(text("□").font(TextStyle::new(20.0, 400.0)).color(theme::subtext()))
}

/// The preview element, exactly `size` points: background, dots, then the fitted drawing.
pub fn view(key: &str, preview: &Preview, size: (f32, f32)) -> El {
    let mut v = el().key(key.to_owned()).size(size.0, size.1).radius(CORNER).clip_rounded(CORNER).fill(theme::surface0());
    v = v.child(canvas(dots(size)).key(format!("{key}-dots")).absolute(0.0, 0.0).size(size.0, size.1));
    let Some(bounds) = preview.bounds else {
        return v.center().child(empty_glyph());
    };
    let camera = preview_camera(bounds, Size::new(size.0 as f64, size.1 as f64));
    v = v.child(canvas(render::shape(&preview.list, &camera)).key(format!("{key}-art")).absolute(0.0, 0.0).size(size.0, size.1));
    render::text_elements(&preview.list, &camera).into_iter().fold(v, |v, t| v.child(t))
}

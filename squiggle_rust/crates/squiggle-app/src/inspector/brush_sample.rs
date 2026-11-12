//! Small renderings of what a brush draws: the entry preview row (`brush_preview.dart`) and the
//! wheel's square swatch (`brush_swatch.dart`). Both paint real features through the core
//! painters, like the canvas does.

use super::metrics::{BRUSH_PREVIEW_HEIGHT, BRUSH_PREVIEW_WIDTH};
use crate::render;
use rune::{El, canvas, el};
use serde_json::{Map, Value};
use squiggle_core::brush_apply::BrushApply;
use squiggle_core::camera::Camera;
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::feature_kinds::{PolylineKind, RectangleKind, TextKind};
use squiggle_core::geom::{Point, Rect, Size};
use squiggle_core::paint::Painter;
use squiggle_core::session::BrushProfile;
use squiggle_core::text_alignment::TextHorizontalAlignment;

/// A clipped `width` x `height` box showing `features` (coordinates in the box).
fn sample_box(features: &[Feature], width: f32, height: f32) -> El {
    let mut painter = Painter::new();
    for feature in features {
        feature.paint(&mut painter);
    }
    let camera = Camera::default();
    let mut holder = el().size(width, height).clip_soft(0.0);
    holder = holder.child(canvas(render::shape(&painter.commands, &camera).view_box(width, height)).absolute(0.0, 0.0).size(width, height));
    for label in render::text_elements(&painter.commands, &camera) {
        holder = holder.child(label);
    }
    holder
}

fn brushed(values: &Map<String, Value>, mut kind: FeatureKind) -> FeatureKind {
    let mut brush = BrushProfile::new("sample", "");
    brush.values = values.clone();
    brush.apply_to(&mut kind);
    kind
}

fn scaled_stroke(kind: &mut FeatureKind, divisor: f64, min: f64, max: f64) {
    if let Some(width) = kind.stroke_width() {
        kind.set_stroke_width((width / divisor).clamp(min, max));
    }
}

/// A rectangle, some text and a line drawn with `values` (the brush menu entries' preview).
pub fn brush_preview(values: &Map<String, Value>) -> El {
    let width = BRUSH_PREVIEW_WIDTH as f64;
    let line_length = (width - 76.0).max(12.0);
    let mut rectangle = brushed(values, FeatureKind::Rectangle(RectangleKind::default()));
    let mut text = brushed(values, FeatureKind::Text(TextKind::new("Aa")));
    let mut line =
        brushed(values, FeatureKind::Polyline(PolylineKind::new(vec![Point::ZERO, Point::new(line_length, 0.0)])));
    // Bound the sample scale: fitting the composition to font size or stroke width would make
    // all thumbnails look identical.
    scaled_stroke(&mut rectangle, 4.0, 0.5, 4.0);
    scaled_stroke(&mut line, 4.0, 0.5, 4.0);
    if let FeatureKind::Text(t) = &mut text {
        t.font_size = (t.font_size * 0.65).clamp(9.0, 22.0);
    }
    let samples = [
        Feature::new(Point::new(3.0, 3.0), Size::new(18.0, 18.0), rectangle),
        Feature::new(Point::new(29.0, 1.0), Size::new(32.0, 22.0), text),
        Feature::new(Point::new(69.0, 12.0), Size::ZERO, line),
    ];
    sample_box(&samples, BRUSH_PREVIEW_WIDTH, BRUSH_PREVIEW_HEIGHT)
}

/// A square sample of `kind` drawn with `values`. Widths and font sizes are compressed rather
/// than scaled to fit, so thin and thick brushes stay distinguishable.
pub fn brush_swatch(values: &Map<String, Value>, kind: &FeatureKind, size: f32) -> El {
    let mut sample = brushed(values, kind.clone());
    let square = size as f64;
    let boxed = Rect::from_ltwh(0.0, 0.0, square, square).deflate(square * 0.23);
    scaled_stroke(&mut sample, 3.0, 1.0, 5.0);
    let feature = match &mut sample {
        FeatureKind::Rectangle(_) | FeatureKind::Circle(_) => Some((boxed.top_left(), boxed.size())),
        FeatureKind::Polyline(line) => {
            let (w, h) = (boxed.width(), boxed.height());
            line.local_points = vec![Point::new(0.0, h), Point::new(w, 0.0)];
            Some((boxed.top_left(), boxed.size()))
        }
        FeatureKind::Text(text) => {
            text.label = "Aa".into();
            text.font_size = (text.font_size * 0.6).clamp(10.0, 20.0);
            text.horizontal_alignment = TextHorizontalAlignment::Center;
            Some((Point::ZERO, Size::new(square, square)))
        }
        FeatureKind::Image(_) => None,
    };
    let features: Vec<Feature> = feature.map(|(origin, size)| Feature::new(origin, size, sample)).into_iter().collect();
    sample_box(&features, size, size)
}

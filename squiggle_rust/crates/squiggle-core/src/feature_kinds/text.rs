//! Text kind (`feature_kind_text.dart`): free text whose box follows its contents.

use crate::color::Color;
use crate::document_colors::DEFAULT_FEATURE_STROKE_COLOR;
use crate::feature::Feature;
use crate::font_size_preset::DEFAULT_FONT_SIZE;
use crate::geom::{Point, Rect, Size};
use crate::inspector::{FieldControl, FieldValue, InspectorField};
use crate::label_layout::LabelLayout;
use crate::paint::Painter;
use crate::painting::text::{MAX_TEXT_FONT_SIZE, MIN_TEXT_FONT_SIZE, measure_text_intrinsic, measure_text_wrapped};
use crate::style_values::{decode_string, decode_style_color, decode_style_enum, decode_style_number, num};
use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
use crate::text_sizing::TextSizing;
use serde_json::{Value, json};

#[derive(Clone, Debug, PartialEq)]
pub struct TextKind {
    /// The text itself (persisted as `contents`).
    pub label: String,
    pub sizing: TextSizing,
    pub font_size: f64,
    pub horizontal_alignment: TextHorizontalAlignment,
    pub stroke_color: Color,
}

impl Default for TextKind {
    fn default() -> Self {
        TextKind::new("")
    }
}

impl TextKind {
    pub fn new(label: impl Into<String>) -> Self {
        TextKind {
            label: label.into(),
            sizing: TextSizing::Auto,
            font_size: DEFAULT_FONT_SIZE,
            horizontal_alignment: TextHorizontalAlignment::Left,
            stroke_color: DEFAULT_FEATURE_STROKE_COLOR,
        }
    }

    pub fn from_json(content: &Value) -> Result<Self, String> {
        Ok(TextKind {
            label: decode_string(content.get("contents"), "contents")?,
            sizing: decode_style_enum(content.get("sizing"))?,
            font_size: decode_style_number(content.get("fontSize"))?,
            horizontal_alignment: decode_style_enum(content.get("horizontalAlignment"))?,
            stroke_color: decode_style_color(content.get("strokeColor"))?,
        })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "type": "text",
            "contents": self.label,
            "sizing": self.sizing.name(),
            "fontSize": num(self.font_size),
            "horizontalAlignment": self.horizontal_alignment.name(),
            "strokeColor": self.stroke_color.0,
        })
    }

    /// Fraction of the box width that stays put when auto-sized text grows: left-aligned text
    /// grows rightward, centered text both ways, and so on.
    pub fn anchor_fraction(&self) -> f64 {
        match self.horizontal_alignment {
            TextHorizontalAlignment::Left => 0.0,
            TextHorizontalAlignment::Center => 0.5,
            TextHorizontalAlignment::Right => 1.0,
        }
    }

    /// Narrowest wrap width: one em, so a column is never one glyph per line.
    pub fn min_wrap_width(&self) -> f64 {
        self.font_size
    }

    pub fn has_visible_stroke(&self) -> bool {
        self.stroke_color.a() > 0
    }

    /// Size of `text` (default: the label) at `font_size`, wrapped at `width` or, when `None`,
    /// not wrapped at all. Empty text measures as one space (one line tall).
    pub fn measure_contents(&self, font_size: f64, width: Option<f64>, text: Option<&str>) -> Size {
        let text = text.unwrap_or(&self.label);
        let contents = if text.is_empty() { " " } else { text };
        match width {
            None => measure_text_intrinsic(contents, font_size),
            Some(w) => measure_text_wrapped(contents, w, font_size),
        }
    }

    /// Where `feature` sits once its box matches `contents` (default: the label) at the font
    /// size. Auto-sized text keeps its alignment point fixed as the width changes; fixed-width
    /// text keeps its width and only its height follows.
    pub fn fitted_bounds(&self, feature: &Feature, contents: Option<&str>) -> Rect {
        let current = current_bounds(feature);
        let width = (self.sizing == TextSizing::FixedWidth).then(|| current.width());
        let size = self.measure_contents(self.font_size, width, contents);
        Rect::from_ltwh(
            current.left + (current.width() - size.width) * self.anchor_fraction(),
            current.top,
            size.width,
            size.height,
        )
    }

    /// Sets the contents and refits the feature's box.
    pub fn set_label(&mut self, feature: &mut Feature, value: &str) {
        self.label = value.to_owned();
        self.refit(Some(feature));
    }

    /// Drops a fixed width so the box hugs its contents again.
    pub fn make_auto_width(&mut self, feature: &mut Feature) {
        self.sizing = TextSizing::Auto;
        self.refit(Some(feature));
    }

    pub fn bounds_for(&self, feature: &Feature) -> Rect {
        current_bounds(feature)
    }

    pub fn hit_test(&self, feature: &Feature, p: Point) -> bool {
        current_bounds(feature).contains(p)
    }

    pub fn intersects_rect(&self, feature: &Feature, rect: &Rect) -> bool {
        current_bounds(feature).overlaps(rect)
    }

    /// Height always follows the contents, so a resize that only changes the width reflows the
    /// text at that width, making it fixed-width. Any other resize scales the font with the box.
    pub fn apply_bounds(&mut self, feature: &mut Feature, bounds: Rect) {
        let current = current_bounds(feature);
        let size = self.resized_size(&bounds, &current);
        feature.set_bounds(Rect::from_ltwh(
            aligned_start(bounds.left, bounds.right, current.left, current.right, size.width),
            aligned_start(bounds.top, bounds.bottom, current.top, current.bottom, size.height),
            size.width,
            size.height,
        ));
    }

    pub fn paint(&self, feature: &Feature, painter: &mut Painter) {
        if !feature.hide_label {
            self.label_layout(feature).paint(painter, &self.label);
        }
    }

    pub fn label_layout(&self, feature: &Feature) -> LabelLayout {
        self.layout_in(current_bounds(feature))
    }

    /// The layout `feature` would have if its label were `contents`; the inline editor follows
    /// it as the draft grows.
    pub fn label_layout_for(&self, feature: &Feature, contents: &str) -> LabelLayout {
        self.layout_in(self.fitted_bounds(feature, Some(contents)))
    }

    pub fn fields(&self) -> Vec<InspectorField> {
        vec![
            InspectorField::new("strokeColor", "Stroke Color", FieldControl::Color, FieldValue::Color(self.stroke_color)),
            InspectorField::new(
                "horizontalAlignment",
                "Horizontal Alignment",
                FieldControl::HorizontalAlignment,
                FieldValue::HorizontalAlignment(self.horizontal_alignment),
            ),
            InspectorField::new("fontSize", "Font Size", FieldControl::FontSize, FieldValue::Number(self.font_size)),
        ]
    }

    /// Alignment and font size changes refit `feature` when one is given.
    pub fn set_field(&mut self, key: &str, value: &FieldValue, feature: Option<&mut Feature>) -> bool {
        match (key, *value) {
            ("strokeColor", FieldValue::Color(v)) => self.stroke_color = v,
            ("horizontalAlignment", FieldValue::HorizontalAlignment(v)) => {
                self.horizontal_alignment = v;
                self.refit(feature);
            }
            ("fontSize", FieldValue::Number(v)) => {
                self.font_size = v;
                self.refit(feature);
            }
            _ => return false,
        }
        true
    }

    fn resized_size(&mut self, bounds: &Rect, current: &Rect) -> Size {
        if is_width_only(bounds, current) {
            self.sizing = TextSizing::FixedWidth;
            return self.measure_contents(self.font_size, Some(bounds.width().max(self.min_wrap_width())), None);
        }
        let base_font_size = self.font_size;
        let scale = projected_scale(bounds.size(), current.size());
        self.font_size = (base_font_size * scale).clamp(MIN_TEXT_FONT_SIZE, MAX_TEXT_FONT_SIZE);
        let width = (self.sizing == TextSizing::FixedWidth).then(|| current.width() * self.font_size / base_font_size);
        self.measure_contents(self.font_size, width, None)
    }

    fn refit(&self, feature: Option<&mut Feature>) {
        if let Some(feature) = feature {
            let bounds = self.fitted_bounds(feature, None);
            feature.set_bounds(bounds);
        }
    }

    fn layout_in(&self, bounds: Rect) -> LabelLayout {
        LabelLayout {
            bounds,
            font_size: self.font_size,
            color: self.stroke_color,
            horizontal_alignment: self.horizontal_alignment,
            vertical_alignment: TextVerticalAlignment::Top,
        }
    }
}

/// The feature's own box (the text kind has no bounds beyond it).
fn current_bounds(feature: &Feature) -> Rect {
    Rect::from_origin_size(feature.origin, feature.size)
}

/// Start of a box of `extent` placed within `to_start..to_end` on one axis. It keeps to
/// whichever edge of the resized range still touches an edge of the original
/// `from_start..from_end`, i.e. the side that stayed put, so the text follows the cursor; with
/// neither, as when resizing from the centre, it is centred.
fn aligned_start(to_start: f64, to_end: f64, from_start: f64, from_end: f64, extent: f64) -> f64 {
    let touches = |edge: f64| is_close(edge, from_start) || is_close(edge, from_end);
    if touches(to_start) {
        to_start
    } else if touches(to_end) {
        to_end - extent
    } else {
        (to_start + to_end - extent) / 2.0
    }
}

fn is_width_only(bounds: &Rect, current: &Rect) -> bool {
    is_close(bounds.height(), current.height()) && !is_close(bounds.width(), current.width())
}

fn is_close(a: f64, b: f64) -> bool {
    (a - b).abs() < 1e-6
}

/// Scale of `base` that `target` corresponds to, taken by projecting the target size onto the
/// base's diagonal. Unlike picking the larger of the width and height ratios, it has no
/// switch-over point where it jumps.
fn projected_scale(target: Size, base: Size) -> f64 {
    let diagonal_squared = base.width * base.width + base.height * base.height;
    if diagonal_squared == 0.0 {
        return 1.0;
    }
    (target.width * base.width + target.height * base.height) / diagonal_squared
}

#[cfg(test)]
mod tests;

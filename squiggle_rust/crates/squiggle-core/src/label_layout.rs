//! How a feature's label is typeset (`label_layout.dart`), plus the shared label metrics of
//! shapes with inner labels.
//!
//! Both canvas painting and the inline text editor read [`LabelLayout`], so the rendered text and
//! the edit field cannot disagree about box, size, or alignment.

use crate::color::Color;
use crate::feature::Feature;
use crate::geom::{Point, Rect, Size};
use crate::paint::Painter;
use crate::painting::text::{measure_text_wrapped, paint_text};
use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment, text_origin_in_bounds};

pub const LABEL_FONT_SIZE: f64 = 24.0;
pub const LABEL_PADDING: f64 = 8.0;

/// Where and how a label is typeset, in its parent's coordinates.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct LabelLayout {
    pub bounds: Rect,
    pub font_size: f64,
    pub color: Color,
    pub horizontal_alignment: TextHorizontalAlignment,
    pub vertical_alignment: TextVerticalAlignment,
}

impl LabelLayout {
    pub fn shifted(&self, offset: Point) -> LabelLayout {
        LabelLayout { bounds: self.bounds.shift(offset), ..*self }
    }

    /// Emits the label as a text command (nothing for empty text).
    pub fn paint(&self, painter: &mut Painter, text: &str) {
        paint_text(
            painter,
            text,
            self.bounds,
            self.font_size,
            Some(self.color),
            self.horizontal_alignment,
            self.vertical_alignment,
        );
    }

    /// Top-left of the text block for `text`, honoring vertical alignment.
    pub fn text_origin(&self, text: &str) -> Point {
        let measured = if text.is_empty() { " " } else { text };
        let height = measure_text_wrapped(measured, self.bounds.width(), self.font_size).height;
        text_origin_in_bounds(self.bounds, height, self.vertical_alignment)
    }
}

/// `bounds` shrunk by the label padding on every side (never negative).
pub fn padded_label_bounds(bounds: Rect) -> Rect {
    let width = (bounds.width() - 2.0 * LABEL_PADDING).max(0.0);
    let height = (bounds.height() - 2.0 * LABEL_PADDING).max(0.0);
    Rect::from_center(bounds.center(), width, height)
}

/// Padded rectangle inscribed in the ellipse (a `1/sqrt(2)` box) that fits `bounds`.
pub fn inscribed_label_bounds(bounds: Rect) -> Rect {
    let scaled = Rect::from_center(
        bounds.center(),
        bounds.width() / std::f64::consts::SQRT_2,
        bounds.height() / std::f64::consts::SQRT_2,
    );
    padded_label_bounds(scaled)
}

/// Height of `label` wrapped at `width` at the default label font size.
pub fn measured_label_height(label: &str, width: f64) -> f64 {
    measure_text_wrapped(label, width.max(1.0), LABEL_FONT_SIZE).height
}

/// Grows (never shrinks) the feature's height so `label` fits in `label_bounds`.
pub fn grow_height_to_fit_label(feature: &mut Feature, label: &str, label_bounds: Rect, outer_height_scale: f64) {
    if label.is_empty() {
        return;
    }
    let required = (measured_label_height(label, label_bounds.width()) + 2.0 * LABEL_PADDING) * outer_height_scale;
    if required > feature.height() {
        feature.size = Size::new(feature.width(), required);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paint::DrawCmd;

    fn layout() -> LabelLayout {
        LabelLayout {
            bounds: Rect::from_ltwh(10.0, 20.0, 100.0, 80.0),
            font_size: 24.0,
            color: Color::WHITE,
            horizontal_alignment: TextHorizontalAlignment::Center,
            vertical_alignment: TextVerticalAlignment::Center,
        }
    }

    #[test]
    fn padded_bounds_shrink_and_clamp() {
        assert_eq!(padded_label_bounds(Rect::from_ltwh(0.0, 0.0, 100.0, 50.0)), Rect::from_ltwh(8.0, 8.0, 84.0, 34.0));
        assert!(padded_label_bounds(Rect::from_ltwh(0.0, 0.0, 10.0, 10.0)).is_empty());
    }

    #[test]
    fn shifted_moves_bounds_only() {
        let shifted = layout().shifted(Point::new(5.0, -5.0));
        assert_eq!(shifted.bounds, Rect::from_ltwh(15.0, 15.0, 100.0, 80.0));
        assert_eq!(shifted.font_size, 24.0);
    }

    #[test]
    fn paint_emits_text_command_for_nonempty_label() {
        let mut painter = Painter::new();
        layout().paint(&mut painter, "hi");
        layout().paint(&mut painter, "");
        assert!(matches!(&painter.commands[..], [DrawCmd::Text { text, .. }] if text == "hi"));
    }

    #[test]
    fn text_origin_uses_vertical_alignment() {
        let origin = layout().text_origin("");
        let line = measure_text_wrapped(" ", 100.0, 24.0).height;
        assert_eq!(origin, Point::new(10.0, 20.0 + (80.0 - line) / 2.0));
    }
}

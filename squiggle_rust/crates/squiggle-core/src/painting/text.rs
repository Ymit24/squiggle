//! Text measuring and painting (`text_painter.dart`). Measurement goes through
//! [`crate::text_measure`]; painting emits a [`crate::paint::DrawCmd::Text`] that the renderer
//! lays out inside the given rect.

use crate::color::Color;
use crate::geom::{Rect, Size};
use crate::paint::Painter;
use crate::text_alignment::{TextHorizontalAlignment, TextVerticalAlignment};
use crate::text_measure::measure_text;

pub const MIN_TEXT_FONT_SIZE: f64 = 1.0;
pub const MAX_TEXT_FONT_SIZE: f64 = 1000.0;

/// Measures wrapped text at `width`, returning the supplied width and the laid-out height.
pub fn measure_text_wrapped(text: &str, width: f64, font_size: f64) -> Size {
    Size::new(width, measure_text(text, Some(width), font_size).height)
}

/// Measures `text` with no wrapping beyond its explicit line breaks. The width is rounded up so
/// laying the text out at it never wraps.
pub fn measure_text_intrinsic(text: &str, font_size: f64) -> Size {
    let size = measure_text(text, None, font_size);
    Size::new(size.width.ceil(), size.height)
}

/// Emits wrapped text inside `bounds` (the content area; callers supply any padding).
/// A `None` or fully transparent colour, empty text or empty bounds paint nothing.
///
/// Unlike the Dart original there is no clip flag: the display list has no clip command, so
/// overflowing text is the renderer's concern.
pub fn paint_text(
    painter: &mut Painter,
    text: &str,
    bounds: Rect,
    font_size: f64,
    fill_color: Option<Color>,
    horizontal: TextHorizontalAlignment,
    vertical: TextVerticalAlignment,
) {
    let Some(color) = fill_color.filter(|c| c.a() > 0) else { return };
    if text.is_empty() || bounds.is_empty() {
        return;
    }
    painter.text(text, bounds, font_size, color, horizontal.to_h_align(), vertical.to_v_align());
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paint::DrawCmd;

    #[test]
    fn measure_wrapped_returns_width_and_wraps() {
        let text = "one two three four five";
        let wide = measure_text_wrapped(text, 300.0, 20.0);
        let narrow = measure_text_wrapped(text, 50.0, 20.0);
        assert_eq!(wide.width, 300.0);
        assert_eq!(narrow.width, 50.0);
        assert!(narrow.height > wide.height);
    }

    #[test]
    fn intrinsic_does_not_wrap_and_fits_longest_line() {
        let single = measure_text_intrinsic("one two three four", 24.0);
        let longer = measure_text_intrinsic("one two three four\nshort", 24.0);
        assert_eq!(longer.width, single.width);
        assert!(longer.height > single.height);
        assert_eq!(measure_text_wrapped("one two three four", single.width, 24.0).height, single.height);
    }

    #[test]
    fn intrinsic_width_is_whole_number() {
        let size = measure_text_intrinsic("squiggle", 23.7);
        assert_eq!(size.width, size.width.ceil());
    }

    fn paint(color: Option<Color>, text: &str) -> usize {
        let mut painter = Painter::new();
        let bounds = Rect::from_ltwh(20.0, 20.0, 60.0, 40.0);
        let (h, v) = (TextHorizontalAlignment::Center, TextVerticalAlignment::Center);
        paint_text(&mut painter, text, bounds, 24.0, color, h, v);
        painter.commands.len()
    }

    #[test]
    fn does_not_paint_when_fill_color_is_disabled() {
        assert_eq!(paint(None, "label"), 0);
        assert_eq!(paint(Some(Color::TRANSPARENT), "label"), 0);
    }

    #[test]
    fn paints_a_visible_label() {
        let mut painter = Painter::new();
        let bounds = Rect::from_ltwh(20.0, 20.0, 60.0, 40.0);
        let (h, v) = (TextHorizontalAlignment::Left, TextVerticalAlignment::Bottom);
        paint_text(&mut painter, "label", bounds, 24.0, Some(Color::WHITE), h, v);
        assert!(matches!(&painter.commands[..], [DrawCmd::Text { text, .. }] if text == "label"));
        assert_eq!(paint(Some(Color::WHITE), ""), 0);
    }
}

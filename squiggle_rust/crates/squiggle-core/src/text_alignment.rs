//! Text alignment enums and placement helper (`text_alignment.dart`).

use crate::geom::{Point, Rect};
use crate::paint::{HAlign, VAlign};
use crate::style_values::style_enum;

style_enum! {
    pub enum TextHorizontalAlignment { Left => "left", Center => "center", Right => "right" }
}

style_enum! {
    pub enum TextVerticalAlignment { Top => "top", Center => "center", Bottom => "bottom" }
}

impl TextHorizontalAlignment {
    pub fn to_h_align(self) -> HAlign {
        match self {
            Self::Left => HAlign::Left,
            Self::Center => HAlign::Center,
            Self::Right => HAlign::Right,
        }
    }
}

impl TextVerticalAlignment {
    pub fn to_v_align(self) -> VAlign {
        match self {
            Self::Top => VAlign::Top,
            Self::Center => VAlign::Middle,
            Self::Bottom => VAlign::Bottom,
        }
    }

    pub fn y_offset(self, bounds_height: f64, text_height: f64) -> f64 {
        match self {
            Self::Top => 0.0,
            Self::Center => (bounds_height - text_height) / 2.0,
            Self::Bottom => bounds_height - text_height,
        }
    }
}

/// Top-left of a text block of `text_height` placed in `bounds`.
pub fn text_origin_in_bounds(bounds: Rect, text_height: f64, vertical: TextVerticalAlignment) -> Point {
    let top_left = bounds.top_left();
    Point::new(top_left.x, top_left.y + vertical.y_offset(bounds.height(), text_height))
}

#[cfg(test)]
mod tests {
    use super::*;

    const BOUNDS: Rect = Rect::from_ltrb(10.0, 20.0, 110.0, 100.0);

    #[test]
    fn top_alignment_uses_top_left_corner() {
        assert_eq!(text_origin_in_bounds(BOUNDS, 24.0, TextVerticalAlignment::Top), Point::new(10.0, 20.0));
    }

    #[test]
    fn center_alignment_offsets_vertically() {
        assert_eq!(text_origin_in_bounds(BOUNDS, 24.0, TextVerticalAlignment::Center), Point::new(10.0, 48.0));
    }

    #[test]
    fn bottom_alignment_pins_text_to_bottom_edge() {
        assert_eq!(text_origin_in_bounds(BOUNDS, 24.0, TextVerticalAlignment::Bottom), Point::new(10.0, 76.0));
    }

    #[test]
    fn persisted_names_round_trip() {
        for a in TextHorizontalAlignment::ALL {
            assert_eq!(TextHorizontalAlignment::from_name(a.name()), Some(*a));
        }
        assert_eq!(TextVerticalAlignment::from_name("middle"), None);
    }
}

//! Placement of newly created text features (`text_feature_placement.dart`).

use crate::document_colors::DEFAULT_NEW_TEXT_FILL_COLOR;
use crate::feature::Feature;
use crate::feature_kind::FeatureKind;
use crate::feature_kinds::TextKind;
use crate::geom::Point;
use crate::text_sizing::TextSizing;

/// A new text feature placed at `origin`.
///
/// Without `fixed_width` the text is auto-sized and `origin` is its alignment point, so centered
/// text is centered on it. With `fixed_width`, `origin` is the top-left of a box that wraps at
/// that width. `configure_kind` runs on the fresh kind first (e.g. to apply a brush).
pub fn new_text_feature_at(
    origin: Point,
    contents: &str,
    fixed_width: Option<f64>,
    configure_kind: Option<&dyn Fn(&mut TextKind)>,
) -> Feature {
    let mut kind = TextKind::new(contents);
    kind.stroke_color = DEFAULT_NEW_TEXT_FILL_COLOR;
    if let Some(configure) = configure_kind {
        configure(&mut kind);
    }
    // The gesture decides the sizing, whatever the brush says.
    kind.sizing = if fixed_width.is_none() { TextSizing::Auto } else { TextSizing::FixedWidth };
    let width = fixed_width.map(|w| w.max(kind.min_wrap_width()));
    let size = kind.measure_contents(kind.font_size, width, None);
    let anchor_shift = if width.is_none() { size.width * kind.anchor_fraction() } else { 0.0 };
    Feature::new(Point::new(origin.x - anchor_shift, origin.y), size, FeatureKind::Text(kind))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::text_alignment::TextHorizontalAlignment;

    fn text(feature: &Feature) -> &TextKind {
        match &feature.kind {
            FeatureKind::Text(t) => t,
            other => panic!("expected text, got {other:?}"),
        }
    }

    #[test]
    fn auto_text_is_anchored_at_origin() {
        let configure = |k: &mut TextKind| k.horizontal_alignment = TextHorizontalAlignment::Center;
        let feature = new_text_feature_at(Point::new(100.0, 50.0), "hello", None, Some(&configure));
        assert_eq!(feature.origin.x + feature.size.width / 2.0, 100.0);
        assert_eq!(feature.origin.y, 50.0);
        assert_eq!(text(&feature).sizing, TextSizing::Auto);
    }

    #[test]
    fn fixed_width_text_wraps_and_never_goes_below_one_em() {
        let feature = new_text_feature_at(Point::new(10.0, 10.0), "one two three", Some(2.0), None);
        assert_eq!(feature.origin, Point::new(10.0, 10.0));
        assert_eq!(feature.size.width, 24.0);
        assert_eq!(text(&feature).sizing, TextSizing::FixedWidth);
    }

    #[test]
    fn gesture_overrides_brush_sizing() {
        let configure = |k: &mut TextKind| k.sizing = TextSizing::FixedWidth;
        let feature = new_text_feature_at(Point::ZERO, "x", None, Some(&configure));
        assert_eq!(text(&feature).sizing, TextSizing::Auto);
    }
}

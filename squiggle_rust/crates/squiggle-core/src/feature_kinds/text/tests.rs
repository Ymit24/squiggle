use super::*;
use crate::feature_kind::FeatureKind;
use crate::geom::Size;
use crate::paint::DrawCmd;
use crate::feature_geometry::rect_from_anchor_with_aspect_ratio;
use serde_json::json;

fn content() -> Value {
    json!({
        "type": "text",
        "contents": "Hello",
        "sizing": "fixedWidth",
        "fontSize": 24.5,
        "horizontalAlignment": "center",
        "strokeColor": 0xFF112233u32,
    })
}

fn p(x: f64, y: f64) -> Point {
    Point::new(x, y)
}

fn text_of(feature: &Feature) -> &TextKind {
    match &feature.kind {
        FeatureKind::Text(t) => t,
        other => panic!("expected text, got {other:?}"),
    }
}

fn feature_with(kind: TextKind, origin: Point, size: Size) -> Feature {
    Feature::new(origin, size, FeatureKind::Text(kind))
}

fn close(a: f64, b: f64) {
    assert!((a - b).abs() < 1e-9, "{a} != {b}");
}

#[test]
fn from_json_preserves_text_and_style_fields() {
    let kind = TextKind::from_json(&content()).unwrap();
    assert_eq!(kind.label, "Hello");
    assert_eq!(kind.sizing, TextSizing::FixedWidth);
    assert_eq!(kind.font_size, 24.5);
    assert_eq!(kind.horizontal_alignment, TextHorizontalAlignment::Center);
    assert_eq!(kind.stroke_color, Color(0xFF11_2233));
}

#[test]
fn to_json_emits_all_text_and_style_fields_and_round_trips() {
    let mut kind = TextKind::new("Hello");
    kind.sizing = TextSizing::FixedWidth;
    kind.font_size = 24.5;
    kind.horizontal_alignment = TextHorizontalAlignment::Center;
    kind.stroke_color = Color(0xFF11_2233);
    assert_eq!(kind.to_json(), content());
    assert_eq!(TextKind::from_json(&kind.to_json()).unwrap(), kind);
}

#[test]
fn invalid_alignment_names_are_errors() {
    let mut data = content();
    data["horizontalAlignment"] = json!("invalid");
    assert!(TextKind::from_json(&data).is_err());
}

#[test]
fn fixed_width_set_label_keeps_width_and_fits_height() {
    let mut kind = TextKind::new("short");
    kind.sizing = TextSizing::FixedWidth;
    let mut feature = feature_with(kind, p(10.0, 20.0), Size::new(100.0, 200.0));

    feature.set_label("a long line that wraps across several lines");

    assert_eq!(feature.origin, p(10.0, 20.0));
    assert_eq!(feature.width(), 100.0);
    assert_eq!(feature.height(), text_of(&feature).measure_contents(24.0, Some(100.0), None).height);
    assert_eq!(text_of(&feature).font_size, 24.0);
}

#[test]
fn auto_width_grows_to_the_longest_line_without_wrapping() {
    let kind = TextKind::new("a");
    let size = kind.measure_contents(24.0, None, None);
    let mut feature = feature_with(kind, p(10.0, 20.0), size);
    let one_line_height = feature.height();

    feature.set_label("a much longer single line of text");

    assert!(feature.width() > 200.0);
    assert_eq!(feature.height(), one_line_height);
    assert_eq!(feature.origin, p(10.0, 20.0));
}

#[test]
fn auto_width_keeps_the_alignment_point_fixed() {
    for (alignment, anchor) in [
        (TextHorizontalAlignment::Left, 0.0),
        (TextHorizontalAlignment::Center, 0.5),
        (TextHorizontalAlignment::Right, 1.0),
    ] {
        let mut kind = TextKind::new("a");
        kind.horizontal_alignment = alignment;
        let size = kind.measure_contents(kind.font_size, None, None);
        let mut feature = feature_with(kind, p(100.0, 0.0), size);
        let anchor_x = feature.origin.x + feature.width() * anchor;

        feature.set_label("much longer");

        close(feature.origin.x + feature.width() * anchor, anchor_x);
    }
}

#[test]
fn empty_content_has_the_height_of_one_line() {
    let mut kind = TextKind::new("text");
    kind.sizing = TextSizing::FixedWidth;
    let mut feature = feature_with(kind, Point::ZERO, Size::new(100.0, 200.0));

    feature.set_label("");

    assert!(feature.height() > 0.0);
    assert_eq!(feature.height(), text_of(&feature).measure_contents(24.0, Some(100.0), None).height);
}

mod resizing {
    use super::*;

    fn text_feature(sizing: TextSizing) -> Feature {
        let mut kind = TextKind::new("one two three four five six");
        kind.sizing = sizing;
        let width = (sizing == TextSizing::FixedWidth).then_some(200.0);
        let size = kind.measure_contents(24.0, width, None);
        feature_with(kind, p(100.0, 100.0), size)
    }

    /// `start` scaled by `factor`, keeping the point at `pin` (0..=1 fractions of the box) fixed.
    fn scaled_bounds(start: Rect, factor: f64, pin: (f64, f64)) -> Rect {
        let size = start.size() * factor;
        let anchor = p(start.left + start.width() * pin.0, start.top + start.height() * pin.1);
        Rect::from_ltwh(anchor.x - size.width * pin.0, anchor.y - size.height * pin.1, size.width, size.height)
    }

    const TOP_LEFT: (f64, f64) = (0.0, 0.0);
    const BOTTOM_RIGHT: (f64, f64) = (1.0, 1.0);
    const CENTER: (f64, f64) = (0.5, 0.5);

    #[test]
    fn a_uniform_resize_scales_the_font_about_the_corner_that_stays() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(scaled_bounds(start, 2.0, TOP_LEFT));

        close(text_of(&feature).font_size, 48.0);
        assert_eq!(feature.origin, start.top_left());
        assert!((feature.width() - start.width() * 2.0).abs() < 3.0);
    }

    #[test]
    fn keeps_the_bottom_right_corner_when_that_is_the_one_that_stays() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(scaled_bounds(start, 0.5, BOTTOM_RIGHT));

        close(text_of(&feature).font_size, 12.0);
        let end = feature.local_bounds();
        close(end.right, start.right);
        close(end.bottom, start.bottom);
    }

    #[test]
    fn a_resize_flipped_past_the_start_grows_the_other_way() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(Rect::from_ltrb(
            start.left - start.width(),
            start.top - start.height(),
            start.left,
            start.top,
        ));

        let end = feature.local_bounds();
        close(end.right, start.left);
        close(end.bottom, start.top);
    }

    #[test]
    fn a_resize_about_the_centre_keeps_the_centre() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(scaled_bounds(start, 2.0, CENTER));

        close(feature.local_bounds().center().x, start.center().x);
        close(feature.local_bounds().center().y, start.center().y);
    }

    #[test]
    fn font_size_changes_smoothly_as_a_locked_corner_moves() {
        let start = text_feature(TextSizing::Auto).local_bounds();
        let snapshot = text_feature(TextSizing::Auto).to_json();
        let mut previous: Option<f64> = None;

        // Sweep the pointer from a horizontal-only to a vertical-heavy drag, locked to the
        // start's aspect ratio as the select tool does for text.
        for step in 0..=100 {
            let t = step as f64 / 100.0;
            let mut feature = Feature::from_json(&snapshot).unwrap();
            feature.resize(rect_from_anchor_with_aspect_ratio(
                start.top_left(),
                p(start.right + 40.0 * (1.0 - t), start.bottom + 40.0 * t),
                start.width() / start.height(),
            ));
            let font_size = text_of(&feature).font_size;
            if let Some(previous) = previous {
                assert!((font_size - previous).abs() < 0.5, "{previous} -> {font_size}");
            }
            previous = Some(font_size);
        }
    }

    #[test]
    fn a_width_only_resize_sets_the_wrap_width_and_keeps_the_font() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(Rect::from_ltrb(start.left, start.top, start.left + 120.0, start.bottom));

        let kind = text_of(&feature);
        assert_eq!(kind.sizing, TextSizing::FixedWidth);
        assert_eq!(kind.font_size, 24.0);
        assert_eq!(feature.width(), 120.0);
        assert_eq!(feature.origin, start.top_left());
        assert_eq!(feature.height(), kind.measure_contents(24.0, Some(120.0), None).height);
        assert!(feature.height() > start.height());
    }

    #[test]
    fn a_width_only_resize_keeps_the_edge_that_stays() {
        let mut feature = text_feature(TextSizing::FixedWidth);
        let start = feature.local_bounds();

        feature.resize(Rect::from_ltrb(start.right - 100.0, start.top, start.right, start.bottom));

        assert_eq!(feature.local_bounds().right, start.right);
        assert_eq!(feature.width(), 100.0);
    }

    #[test]
    fn a_width_only_resize_never_goes_narrower_than_one_em() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(Rect::from_ltrb(start.left, start.top, start.left + 1.0, start.bottom));

        assert_eq!(feature.width(), 24.0);
    }

    #[test]
    fn a_resize_sharing_no_edge_with_the_start_centres_the_text() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();
        let target = Rect::from_ltwh(0.0, 0.0, start.width() / 2.0, start.height() / 2.0);

        feature.resize(target);

        close(text_of(&feature).font_size, 12.0);
        close(feature.local_bounds().center().x, target.center().x);
        close(feature.local_bounds().center().y, target.center().y);
    }

    #[test]
    fn resizing_to_the_same_box_changes_nothing() {
        let mut feature = text_feature(TextSizing::Auto);
        let start = feature.local_bounds();

        feature.resize(start);

        assert_eq!(text_of(&feature).sizing, TextSizing::Auto);
        assert_eq!(feature.local_bounds(), start);
    }
}

#[test]
fn make_auto_width_drops_the_wrap_width() {
    let mut kind = TextKind::new("hello");
    kind.sizing = TextSizing::FixedWidth;
    let expected = kind.measure_contents(24.0, None, None).width;
    let mut feature = feature_with(kind, Point::ZERO, Size::new(400.0, 40.0));

    feature.make_text_auto_width();

    assert_eq!(text_of(&feature).sizing, TextSizing::Auto);
    assert_eq!(feature.width(), expected);
}

#[test]
fn paints_the_label_in_stroke_color_unless_hidden() {
    let mut feature = feature_with(TextKind::new("hi"), p(5.0, 6.0), Size::new(40.0, 30.0));
    let paint = |f: &Feature| {
        let mut painter = crate::paint::Painter::new();
        f.paint(&mut painter);
        painter.commands
    };
    let cmds = paint(&feature);
    assert!(matches!(&cmds[..], [DrawCmd::Text { text, color, rect, .. }]
        if text == "hi" && *color == Color::WHITE && *rect == Rect::from_ltwh(5.0, 6.0, 40.0, 30.0)));
    feature.hide_label = true;
    assert!(paint(&feature).is_empty());
}

#[test]
fn label_layout_for_follows_a_growing_draft() {
    let kind = TextKind::new("a");
    let size = kind.measure_contents(24.0, None, None);
    let feature = feature_with(kind, p(10.0, 10.0), size);
    let layout = text_of(&feature).label_layout_for(&feature, "a much longer draft");
    assert!(layout.bounds.width() > feature.width());
    assert_eq!(layout.bounds.left, 10.0);
    assert_eq!(layout.vertical_alignment, TextVerticalAlignment::Top);
}

use super::*;
use crate::feature_kind::FeatureKind;
use crate::geom::Size;
use crate::paint::DrawCmd;
use serde_json::json;

#[test]
fn from_json_preserves_image_id_and_stroke_fields() {
    let kind = ImageKind::from_json(&json!({
        "type": "image",
        "imageId": "image-id",
        "strokeColor": 0xFF112233u32,
        "fillColor": 0xFF445566u32,
        "strokeWidth": 3.5,
    }))
    .unwrap();
    assert_eq!(kind.image_id, "image-id");
    assert_eq!(kind.stroke_color, Color(0xFF11_2233));
    assert_eq!(kind.stroke_width, 3.5);
}

#[test]
fn to_json_emits_image_id_and_stroke_fields_and_round_trips() {
    let mut kind = ImageKind::new("image-id");
    kind.stroke_color = Color(0xFF11_2233);
    kind.stroke_width = 3.5;
    let expected = json!({
        "type": "image",
        "imageId": "image-id",
        "strokeColor": 0xFF112233u32,
        "strokeWidth": 3.5,
    });
    assert_eq!(kind.to_json(), expected);
    assert_eq!(ImageKind::from_json(&expected).unwrap(), kind);
}

#[test]
fn supports_stroke_color_and_width_but_not_fill() {
    let mut kind = FeatureKind::Image(ImageKind::new("img_test.png"));
    assert!(kind.stroke_color().is_some());
    assert!(kind.stroke_width().is_some());
    assert_eq!(kind.fill_color(), None);
    assert!(!kind.set_fill_color(Color::WHITE));
    assert!(!kind.has_visible_stroke(), "no visible stroke by default");
    assert!(kind.set_stroke_color(Color(0xFFFF_0000)));
    assert!(kind.set_stroke_width(4.0));
    assert_eq!((kind.stroke_color(), kind.stroke_width()), (Some(Color(0xFFFF_0000)), Some(4.0)));
}

#[test]
fn paints_image_then_optional_outline() {
    let feature =
        |kind: ImageKind| Feature::new(Point::new(1.0, 2.0), Size::new(30.0, 20.0), FeatureKind::Image(kind));
    let paint = |f: &Feature| {
        let mut painter = crate::paint::Painter::new();
        f.paint(&mut painter);
        painter.commands
    };
    let plain = paint(&feature(ImageKind::new("abc")));
    assert!(matches!(&plain[..], [DrawCmd::Image { image_id, rect }]
        if image_id == "abc" && *rect == Rect::from_ltwh(1.0, 2.0, 30.0, 20.0)));

    let mut outlined = ImageKind::new("abc");
    outlined.stroke_color = Color::WHITE;
    let cmds = paint(&feature(outlined));
    assert!(matches!(&cmds[..], [DrawCmd::Image { .. }, DrawCmd::Stroke { closed: true, .. }]));
}

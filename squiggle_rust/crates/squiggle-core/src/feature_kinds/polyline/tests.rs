use super::*;
use crate::document::Document;
use crate::feature_kind::FeatureKind;
use crate::geom::Size;
use crate::node::Node;
use crate::paint::DrawCmd;
use serde_json::json;

fn p(x: f64, y: f64) -> Point {
    Point::new(x, y)
}

fn line_feature(origin: Point, size: Size, points: Vec<Point>) -> Feature {
    Feature::new(origin, size, FeatureKind::Polyline(PolylineKind::new(points)))
}

fn default_line() -> Feature {
    line_feature(Point::ZERO, Size::new(100.0, 100.0), vec![Point::ZERO, p(100.0, 100.0)])
}

fn polyline(feature: &mut Feature) -> &mut PolylineKind {
    match &mut feature.kind {
        FeatureKind::Polyline(k) => k,
        other => panic!("expected polyline, got {other:?}"),
    }
}

fn world_point(feature: &Feature, index: usize) -> Point {
    match &feature.kind {
        FeatureKind::Polyline(k) => feature.origin + k.local_points[index],
        other => panic!("expected polyline, got {other:?}"),
    }
}

#[test]
fn to_json_emits_type_and_encodes_points() {
    let kind = PolylineKind::new(vec![p(1.5, -2.5), p(10.0, 20.0)]);
    assert_eq!(
        kind.to_json(),
        json!({
            "type": "polyline",
            "localPoints": [{ "x": 1.5, "y": -2.5 }, { "x": 10.0, "y": 20.0 }],
            "strokeColor": kind.stroke_color.0,
            "strokeType": "solid",
            "strokeWidth": kind.stroke_width,
            "startEndCap": "rounded",
            "endEndCap": "rounded",
        })
    );
    assert_eq!(PolylineKind::new(vec![]).to_json()["localPoints"], json!([]));
}

#[test]
fn round_trip_preserves_points_and_style_fields() {
    let mut kind = PolylineKind::new(vec![p(1.5, -2.5), p(10.0, 20.0)]);
    kind.stroke_color = Color(0xFF11_2233);
    kind.stroke_width = 3.5;
    kind.start_end_cap = LineEndCap::Arrow;
    let decoded = PolylineKind::from_json(&kind.to_json()).unwrap();
    assert_eq!(decoded, kind);
    assert_eq!(decoded.end_end_cap, LineEndCap::Rounded);
}

#[test]
fn missing_end_caps_and_stroke_type_decode_with_defaults() {
    let mut data = PolylineKind::new(vec![Point::ZERO, p(10.0, 0.0)]).to_json();
    let map = data.as_object_mut().unwrap();
    map.remove("startEndCap");
    map.remove("endEndCap");
    map.remove("strokeType");
    let decoded = PolylineKind::from_json(&data).unwrap();
    assert_eq!(decoded.start_end_cap, LineEndCap::Rounded);
    assert_eq!(decoded.end_end_cap, LineEndCap::Rounded);
    data["strokeType"] = json!("unknown");
    assert_eq!(PolylineKind::from_json(&data).unwrap().stroke_type, StrokeType::Solid);
}

#[test]
fn stroke_type_round_trips_and_clones() {
    for stroke_type in StrokeType::ALL {
        let mut kind = FeatureKind::Polyline(PolylineKind::new(vec![Point::ZERO, p(100.0, 0.0)]));
        assert!(kind.set_stroke_type(*stroke_type));
        assert_eq!(kind.to_json()["strokeType"], stroke_type.name());
        assert_eq!(FeatureKind::from_json(&kind.to_json()).unwrap().stroke_type(), Some(*stroke_type));
        assert_eq!(kind.clone().stroke_type(), Some(*stroke_type));
    }
}

#[test]
fn bounds_include_stroke_padding_around_centerline_points() {
    let feature = line_feature(p(10.0, 20.0), Size::new(300.0, 80.0), vec![Point::ZERO, p(100.0, 100.0)]);
    assert_eq!(feature.local_bounds(), Rect::from_ltwh(6.0, 16.0, 108.0, 108.0));
}

#[test]
fn hit_test_hits_on_segment_and_misses_off_to_the_side() {
    let feature = line_feature(Point::ZERO, Size::new(100.0, 0.0), vec![Point::ZERO, p(100.0, 0.0)]);
    assert!(feature.hit_test(p(50.0, 0.0)));
    assert!(!feature.hit_test(p(50.0, 40.0)));
}

#[test]
fn hit_test_includes_arrow_heads() {
    let mut feature = line_feature(Point::ZERO, Size::new(100.0, 100.0), vec![Point::ZERO, p(100.0, 0.0)]);
    polyline(&mut feature).end_end_cap = LineEndCap::Arrow;
    assert!(feature.hit_test(p(82.0, 8.5)));
    assert!(!feature.hit_test(p(82.0, 14.0)));
}

#[test]
fn paints_the_line_and_a_solid_arrow_head_with_stroke_color() {
    let mut feature = line_feature(p(30.0, 50.0), Size::new(100.0, 100.0), vec![Point::ZERO, p(100.0, 0.0)]);
    polyline(&mut feature).end_end_cap = LineEndCap::Arrow;
    let mut painter = crate::paint::Painter::new();
    feature.paint(&mut painter);
    let [DrawCmd::Stroke { points, color, .. }, DrawCmd::Fill { points: head, color: head_color }] =
        &painter.commands[..]
    else {
        panic!("expected stroke then arrow fill: {:?}", painter.commands)
    };
    assert_eq!(*color, Color::WHITE);
    assert_eq!(*head_color, Color::WHITE);
    // The line stops where the arrow head starts (arrow length is 24 at width 8).
    assert_eq!(points, &[p(30.0, 50.0), p(106.0, 50.0)]);
    assert_eq!(head[0], p(130.0, 50.0));
    assert!(head.iter().all(|q| q.x >= 105.0 && q.x <= 130.0 + 1e-9));
}

#[test]
fn fewer_than_two_points_paint_nothing_and_never_hit() {
    let feature = line_feature(Point::ZERO, Size::new(10.0, 10.0), vec![Point::ZERO]);
    let mut painter = crate::paint::Painter::new();
    feature.paint(&mut painter);
    assert!(painter.commands.is_empty());
    assert!(!feature.hit_test(Point::ZERO));
    assert!(!feature.intersects_rect(&Rect::from_ltwh(-5.0, -5.0, 10.0, 10.0)));
}

#[test]
fn dashed_polyline_paints_multiple_strokes() {
    let mut feature = line_feature(Point::ZERO, Size::new(100.0, 0.0), vec![Point::ZERO, p(200.0, 0.0)]);
    assert!(feature.kind.set_stroke_type(StrokeType::Dashed));
    let mut painter = crate::paint::Painter::new();
    feature.paint(&mut painter);
    assert!(painter.commands.len() > 1);
}

#[test]
fn intersects_rect_detects_segment_overlap_and_ignores_empty_envelope_gaps() {
    let feature = line_feature(Point::ZERO, Size::new(100.0, 100.0), vec![Point::ZERO, p(100.0, 0.0), p(100.0, 100.0)]);
    assert!(feature.intersects_rect(&Rect::from_ltwh(40.0, -5.0, 20.0, 10.0)));
    assert!(!feature.intersects_rect(&Rect::from_ltwh(10.0, 50.0, 20.0, 20.0)));
}

#[test]
fn intersects_rect_uses_same_tolerance_as_hit_test_for_near_misses() {
    let feature = line_feature(Point::ZERO, Size::new(100.0, 0.0), vec![Point::ZERO, p(100.0, 0.0)]);
    assert!(feature.hit_test(p(50.0, 7.0)));
    assert!(feature.intersects_rect(&Rect::from_ltwh(45.0, 7.0, 10.0, 10.0)));
}

#[test]
fn document_finds_polyline_by_clicking_on_segment() {
    let mut feature = line_feature(Point::ZERO, Size::new(100.0, 0.0), vec![Point::ZERO, p(100.0, 0.0)]);
    feature.id = crate::ids::NodeId(1);
    let doc = Document::from_nodes([Node::Feature(feature)]);
    let hit = doc.node_at_point(p(50.0, 0.0));
    assert_eq!(hit.map(Node::id), Some(crate::ids::NodeId(1)));
}

#[test]
fn translation_keeps_local_points_and_moves_world_points() {
    let mut feature = default_line();
    let before_end = world_point(&feature, 1);
    feature.origin = p(20.0, 30.0);
    assert_eq!(polyline(&mut feature).local_points, vec![Point::ZERO, p(100.0, 100.0)]);
    assert_eq!(world_point(&feature, 1), before_end + p(20.0, 30.0));
}

#[test]
fn resize_scales_world_points_proportionally() {
    let mut feature = default_line();
    feature.resize(Rect::from_ltwh(0.0, 0.0, 200.0, 50.0));
    assert_eq!(feature.local_bounds(), Rect::from_ltwh(0.0, 0.0, 200.0, 50.0));
    assert_eq!(world_point(&feature, 0), p(4.0, 4.0));
    assert_eq!(world_point(&feature, 1), p(196.0, 46.0));
}

#[test]
fn set_point_moves_one_point_and_rebases_on_the_first() {
    let mut feature = default_line();
    feature.set_polyline_point(1, p(50.0, 20.0));
    assert_eq!(feature.origin, Point::ZERO);
    assert_eq!(polyline(&mut feature).local_points, vec![Point::ZERO, p(50.0, 20.0)]);
    assert_eq!(feature.size, feature.local_bounds().size());

    feature.set_polyline_point(0, p(10.0, 10.0));
    assert_eq!(feature.origin, p(10.0, 10.0));
    assert_eq!(world_point(&feature, 1), p(50.0, 20.0));

    feature.set_polyline_point(9, p(1.0, 1.0));
    assert_eq!(world_point(&feature, 1), p(50.0, 20.0));
}

#[test]
fn set_geometry_updates_origin_points_and_size() {
    let mut feature = default_line();
    feature.set_polyline_geometry(p(5.0, 5.0), vec![Point::ZERO, p(20.0, 0.0)]);
    assert_eq!(feature.origin, p(5.0, 5.0));
    assert_eq!(feature.size, Size::new(28.0, 8.0));
}

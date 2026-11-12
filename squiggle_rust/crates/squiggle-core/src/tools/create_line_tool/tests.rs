use super::*;
use crate::feature_geometry::world_points;
use crate::line_end_cap::LineEndCap;
use crate::stroke_type::StrokeType;
use crate::stroke_width::DEFAULT_STROKE_WIDTH;
use crate::tools::test_util::*;
use serde_json::json;

fn setup() -> Sim {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateLineTool::new()));
    sim
}

fn is_select(sim: &Sim) -> bool {
    sim.ctx.tool.active().is_some_and(|t| t.create_drawing_kind().is_none())
}

fn is_line_tool(sim: &Sim) -> bool {
    matches!(sim.ctx.tool.active().and_then(|t| t.create_drawing_kind()), Some(FeatureKind::Polyline(_)))
}

fn polyline(feature: &Feature) -> &PolylineKind {
    match &feature.kind {
        FeatureKind::Polyline(p) => p,
        _ => panic!("not a polyline"),
    }
}

fn points_of(feature: &Feature) -> Vec<Point> {
    world_points(feature.origin, &polyline(feature).local_points)
}

fn only_points(sim: &Sim) -> Vec<Point> {
    assert_eq!(sim.features().len(), 1);
    points_of(sim.features()[0])
}

fn click(sim: &mut Sim, p: Point) {
    sim.down(p);
    sim.up(p);
}

fn enter(sim: &mut Sim) -> bool {
    sim.key(Key::Enter)
}

#[test]
fn line_follows_brush_changes_mid_draw() {
    for placing in [false, true] {
        let mut sim = setup();
        sim.set_brush("strokeWidth", json!(3.0));
        sim.set_brush("endEndCap", json!("arrow"));
        let scratch = sim.active_brush_id();
        let sparse = sim.create_brush("Sparse");
        sim.clear_brush("strokeWidth");
        sim.clear_brush("endEndCap");
        sim.activate_brush(&scratch);

        sim.down(pt(10.0, 20.0));
        if placing {
            sim.up(pt(10.0, 20.0));
            sim.down(pt(110.0, 70.0));
            sim.up(pt(110.0, 70.0));
            sim.hover(pt(210.0, 120.0));
        } else {
            sim.mv(pt(110.0, 70.0));
        }
        sim.activate_brush(&sparse);
        sim.set_brush("strokeColor", json!(0xFF123456u32));
        sim.set_brush("startEndCap", json!("arrow"));
        sim.set_brush("strokeType", json!("dashed"));
        sim.clear_brush("strokeType");
        assert!(sim.ctx.document.nodes().is_empty());
        assert!(!sim.ctx.history.can_undo());

        if placing {
            enter(&mut sim);
        } else {
            sim.up(pt(110.0, 70.0));
        }

        assert_eq!(only_points(&sim), [pt(10.0, 20.0), pt(110.0, 70.0)]);
        let kind = polyline(sim.features()[0]);
        assert_eq!(kind.stroke_width, DEFAULT_STROKE_WIDTH);
        assert_eq!(kind.stroke_type, StrokeType::Solid);
        assert_eq!(kind.stroke_color.0, 0xFF123456);
        assert_eq!(kind.start_end_cap, LineEndCap::Arrow);
        assert_eq!(kind.end_end_cap, LineEndCap::Rounded);

        sim.ctx.undo();
        assert!(sim.ctx.document.nodes().is_empty());
        assert!(!sim.ctx.history.can_undo());
        assert_eq!(sim.active_brush_id(), sparse);
    }
}

#[test]
fn click_without_drag_from_idle_enters_placing_without_creating_feature() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    assert!(sim.ctx.document.nodes().is_empty());
    assert!(is_line_tool(&sim));
}

#[test]
fn locked_lines_reset_between_drag_enter_and_escape_completion() {
    let mut sim = Sim::new();
    sim.ctx.tool.toggle_lock();
    sim.ctx.set_tool(Box::new(CreateLineTool::new()));
    sim.down(Point::ZERO);
    sim.mv(pt(100.0, 100.0));
    sim.up(pt(100.0, 100.0));
    assert!(is_line_tool(&sim));
    assert_eq!(sim.features().len(), 1);
    assert!(sim.ctx.selection.is_empty());
    let previous = sim.ctx.document.nodes()[0].id();
    sim.ctx.selection.set_selection([previous]);

    for key in [Key::Enter, Key::Escape] {
        click(&mut sim, pt(200.0, 200.0));
        click(&mut sim, pt(300.0, 300.0));
        assert!(sim.key(key));
        assert!(is_line_tool(&sim));
        assert_eq!(points_of(sim.features().last().unwrap()), [pt(200.0, 200.0), pt(300.0, 300.0)]);
    }
    assert_eq!(sim.features().len(), 3);
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[previous]);
}

#[test]
fn two_clicks_then_enter_commits_polyline_with_2_points() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    click(&mut sim, pt(100.0, 100.0));
    assert!(sim.ctx.document.nodes().is_empty());
    assert!(is_line_tool(&sim));
    assert!(enter(&mut sim));
    assert!(is_select(&sim));
    assert_eq!(only_points(&sim), [pt(0.0, 0.0), pt(100.0, 100.0)]);
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[sim.features()[0].id]);
}

#[test]
fn three_clicks_then_enter_commits_polyline_with_3_points() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    click(&mut sim, pt(100.0, 0.0));
    click(&mut sim, pt(100.0, 100.0));
    assert!(enter(&mut sim));
    assert_eq!(only_points(&sim), [pt(0.0, 0.0), pt(100.0, 0.0), pt(100.0, 100.0)]);
}

#[test]
fn three_clicks_then_escape_commits_polyline_with_3_points() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    click(&mut sim, pt(100.0, 0.0));
    click(&mut sim, pt(100.0, 100.0));
    assert!(sim.key(Key::Escape));
    assert!(is_select(&sim));
    assert_eq!(sim.features().len(), 1);
}

#[test]
fn enter_or_escape_with_1_point_discards_without_creating_feature() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    assert!(enter(&mut sim));
    assert!(sim.ctx.document.nodes().is_empty());
    assert!(sim.ctx.selection.is_empty());
    assert!(is_select(&sim));

    sim.ctx.set_tool(Box::new(CreateLineTool::new()));
    click(&mut sim, Point::ZERO);
    assert!(sim.key(Key::Escape));
    assert!(sim.ctx.document.nodes().is_empty());
}

#[test]
fn drag_from_idle_commits_2_point_line_on_pointer_up() {
    let mut sim = setup();
    sim.down(pt(0.0, 0.0));
    sim.mv(pt(50.0, 50.0));
    sim.up(pt(50.0, 50.0));
    assert!(is_select(&sim));
    assert_eq!(only_points(&sim), [pt(0.0, 0.0), pt(50.0, 50.0)]);
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[sim.features()[0].id]);
}

#[test]
fn click_then_drag_in_placing_mode_adds_point_at_release_position() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    sim.down(pt(50.0, 50.0));
    sim.mv(pt(100.0, 100.0));
    sim.up(pt(100.0, 100.0));
    assert!(sim.ctx.document.nodes().is_empty());
    assert!(enter(&mut sim));
    assert_eq!(only_points(&sim), [pt(0.0, 0.0), pt(100.0, 100.0)]);
}

#[test]
fn initial_click_uses_press_position_and_placement_uses_release_position() {
    let mut sim = setup();
    sim.camera.zoom = 2.0;
    let movement = sim.camera.screen_length_to_world_length(TOUCH_SLOP);
    sim.down(Point::ZERO);
    sim.mv(pt(movement, 0.0));
    sim.up(pt(movement, 0.0));
    assert!(sim.ctx.document.nodes().is_empty());
    sim.down(pt(100.0, 0.0));
    sim.mv(pt(100.0 + movement, 0.0));
    sim.up(pt(100.0 + movement, 0.0));
    enter(&mut sim);
    assert_eq!(only_points(&sim), [Point::ZERO, pt(100.0 + movement, 0.0)]);
}

#[test]
fn placement_uses_release_position_without_a_move_event() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    sim.down(pt(100.0, 0.0));
    sim.up(pt(103.0, 0.0));
    sim.down(pt(200.0, 0.0));
    sim.up(pt(203.0, 0.0));
    assert!(sim.ctx.document.nodes().is_empty());
    enter(&mut sim);
    assert_eq!(only_points(&sim), [Point::ZERO, pt(103.0, 0.0), pt(203.0, 0.0)]);
}

#[test]
fn placement_snaps_using_release_position_and_release_time_shift() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    sim.down(pt(100.0, 0.0));
    sim.up_with(pt(103.0, 95.0), SHIFT);
    let snapped = snap_point_to_45_degree_angle(Point::ZERO, pt(103.0, 95.0));
    sim.down_with(pt(200.0, 100.0), SHIFT);
    sim.mv_with(pt(250.0, 195.0), SHIFT);
    sim.up(pt(253.0, 195.0));
    enter(&mut sim);
    assert_eq!(only_points(&sim), [Point::ZERO, snapped, pt(253.0, 195.0)]);
}

#[test]
fn unmatched_releases_do_not_place_vertices() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    sim.up(pt(50.0, 0.0));
    click(&mut sim, pt(100.0, 0.0));
    sim.up(pt(150.0, 0.0));
    enter(&mut sim);
    assert_eq!(only_points(&sim), [Point::ZERO, pt(100.0, 0.0)]);
}

#[test]
fn movement_beyond_zoom_adjusted_slop_starts_a_line_drag() {
    let mut sim = setup();
    sim.camera.zoom = 2.0;
    let end = pt(sim.camera.screen_length_to_world_length(TOUCH_SLOP) + 1.0, 0.0);
    sim.down(Point::ZERO);
    sim.mv(end);
    sim.up(end);
    assert_eq!(only_points(&sim), [Point::ZERO, end]);
}

#[test]
fn placement_uses_release_after_moving_away_and_back() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    sim.down(pt(100.0, 0.0));
    sim.mv(pt(200.0, 0.0));
    sim.mv(pt(101.0, 0.0));
    sim.up(pt(102.0, 0.0));
    enter(&mut sim);
    assert_eq!(only_points(&sim), [Point::ZERO, pt(102.0, 0.0)]);
}

#[test]
fn finish_during_placement_press_ignores_the_pending_vertex() {
    for key in [Key::Enter, Key::Escape] {
        for drag in [false, true] {
            let mut sim = setup();
            click(&mut sim, Point::ZERO);
            click(&mut sim, pt(100.0, 0.0));
            sim.hover(pt(200.0, 0.0));
            sim.down(pt(200.0, 0.0));
            if drag {
                sim.mv(pt(300.0, 0.0));
            }
            assert!(sim.key(key));
            sim.up(pt(300.0, 0.0));
            assert_eq!(only_points(&sim), [Point::ZERO, pt(100.0, 0.0)]);
        }
    }
}

#[test]
fn finish_key_discards_the_pending_initial_press() {
    for key in [Key::Enter, Key::Escape] {
        let mut sim = setup();
        sim.down(Point::ZERO);
        assert!(sim.key(key));
        assert!(is_select(&sim));
        sim.up(pt(100.0, 0.0));
        assert!(sim.ctx.document.nodes().is_empty());
        assert!(!sim.key(key));
    }
}

#[test]
fn finish_keys_are_unhandled_while_idle_or_dragging_a_new_line() {
    let mut sim = setup();
    assert!(!sim.key(Key::Enter));
    assert!(!sim.key(Key::Escape));
    sim.down(Point::ZERO);
    sim.mv(pt(100.0, 0.0));
    assert!(!sim.key(Key::Enter));
    assert!(!sim.key(Key::Escape));
    sim.up(pt(100.0, 0.0));
    assert_eq!(sim.features().len(), 1);
}

#[test]
fn release_position_and_shift_determine_the_dragged_endpoint() {
    let mut sim = setup();
    sim.down(Point::ZERO);
    sim.mv(pt(100.0, 0.0));
    sim.up_with(pt(200.0, 195.0), SHIFT);
    assert_eq!(only_points(&sim), [Point::ZERO, snap_point_to_45_degree_angle(Point::ZERO, pt(200.0, 195.0))]);
}

#[test]
fn cancel_discards_placement_and_the_next_gesture_starts_fresh() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    click(&mut sim, pt(100.0, 0.0));
    sim.ctx.cancel_interaction();
    assert!(sim.ctx.document.nodes().is_empty());

    sim.down(pt(200.0, 0.0));
    sim.mv(pt(300.0, 0.0));
    sim.up(pt(300.0, 0.0));
    assert_eq!(only_points(&sim), [pt(200.0, 0.0), pt(300.0, 0.0)]);
    sim.ctx.undo();
    assert!(sim.ctx.document.nodes().is_empty());
    sim.ctx.redo();
    assert_eq!(sim.features().len(), 1);
}

#[test]
fn deactivate_mid_placement_discards_partial_line() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    click(&mut sim, pt(100.0, 100.0));
    sim.ctx.set_tool(Box::new(crate::tools::select_tool::SelectTool::default()));
    assert!(sim.ctx.document.nodes().is_empty());
}

#[test]
fn hover_updates_preview_while_placing() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    sim.hover(pt(200.0, 200.0));
    let mut painter = Painter::new();
    sim.ctx.tool.active().unwrap().paint(&sim.ctx, &sim.camera, &mut painter);
    assert!(!painter.commands.is_empty());
}

#[test]
fn shift_drag_snaps_line_to_45_degree_angle() {
    let mut sim = setup();
    sim.down(pt(0.0, 0.0));
    sim.mv_with(pt(100.0, 95.0), SHIFT);
    sim.up_with(pt(100.0, 95.0), SHIFT);
    let points = points_of(sim.features()[0]);
    assert_eq!(points[0], Point::ZERO);
    assert!((points[1].x - points[1].y).abs() < 0.001);
}

#[test]
fn shift_click_snaps_second_point_to_45_degrees() {
    let mut sim = setup();
    click(&mut sim, pt(0.0, 0.0));
    sim.down_with(pt(100.0, 95.0), SHIFT);
    sim.up_with(pt(100.0, 95.0), SHIFT);
    assert!(enter(&mut sim));
    let points = points_of(sim.features()[0]);
    assert!((points[1].x - points[1].y).abs() < 0.001);
}

#[test]
fn double_click_finishes_placement() {
    let mut sim = setup();
    click(&mut sim, Point::ZERO);
    click(&mut sim, pt(100.0, 0.0));
    crate::editor::tool_model::ToolModel::on_double_click(&mut sim.ctx, pt(100.0, 0.0), &sim.camera);
    assert_eq!(only_points(&sim), [Point::ZERO, pt(100.0, 0.0)]);
    assert!(is_select(&sim));
}

#[test]
fn local_points_from_world_conversions() {
    assert!(local_points_from_world(&[], Point::ZERO).is_empty());
    assert_eq!(
        local_points_from_world(&[pt(10.0, 20.0), pt(110.0, 120.0)], pt(10.0, 20.0)),
        [Point::ZERO, pt(100.0, 100.0)]
    );
}

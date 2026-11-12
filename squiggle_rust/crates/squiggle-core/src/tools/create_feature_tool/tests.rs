use super::*;
use crate::feature_kinds::{CircleKind, RectangleKind};
use crate::tools::select_tool::SelectTool;
use crate::tools::test_util::*;
use serde_json::json;

fn tools() -> Vec<CreateFeatureTool> {
    vec![CreateFeatureTool::rect(), CreateFeatureTool::circle()]
}

fn drag(sim: &mut Sim, start: Point, end: Point, mods: Modifiers) {
    sim.down(start);
    sim.mv(start);
    sim.mv_with(end, mods);
    sim.up_with(end, mods);
}

fn bounds(sim: &Sim, index: usize) -> Rect {
    sim.features()[index].local_bounds()
}

/// The select tool is the only active tool without a drawing kind.
fn is_select(sim: &Sim) -> bool {
    sim.ctx.tool.active().is_some_and(|t| t.create_drawing_kind().is_none())
}

#[test]
fn follows_brush_changes_during_drag() {
    for tool in tools() {
        let template = tool.kind().to_json();
        let mut sim = Sim::new();
        sim.set_brush("strokeWidth", json!(3.0));
        let scratch = sim.active_brush_id();
        let sparse = sim.create_brush("Sparse");
        sim.clear_brush("strokeWidth");
        sim.activate_brush(&scratch);
        sim.ctx.set_tool(Box::new(tool));

        sim.down(pt(10.0, 20.0));
        sim.mv(pt(10.0, 20.0));
        sim.mv(pt(110.0, 70.0));
        sim.activate_brush(&sparse);
        sim.set_brush("fillColor", json!(0xFF123456u32));
        sim.set_brush("strokeType", json!("dashed"));
        sim.clear_brush("strokeType");
        assert!(sim.ctx.document.nodes().is_empty());
        assert!(!sim.ctx.history.can_undo());

        // No further move: commit the already-restyled preview.
        sim.up(pt(110.0, 70.0));
        let styles = Sim::content(sim.features()[0]);
        assert_eq!(styles["strokeWidth"], template["strokeWidth"]);
        assert_eq!(styles["strokeType"], "solid");
        assert_eq!(styles["fillColor"], 0xFF123456u32);
        assert_eq!(bounds(&sim, 0), Rect::from_ltwh(10.0, 20.0, 100.0, 50.0));

        sim.ctx.undo();
        assert!(sim.ctx.document.nodes().is_empty());
        assert!(!sim.ctx.history.can_undo());
        assert_eq!(sim.active_brush_id(), sparse);
        sim.ctx.redo();
        assert_eq!(Sim::content(sim.features()[0]), styles);
    }
}

#[test]
fn lock_allows_repeated_shapes_and_follows_manual_tool_changes() {
    let mut sim = Sim::new();
    assert!(!sim.ctx.tool.is_locked());
    sim.ctx.tool.toggle_lock();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));

    let draw = |sim: &mut Sim, start: Point| drag(sim, start, start + pt(100.0, 50.0), NONE);
    draw(&mut sim, Point::ZERO);
    assert!(sim.ctx.selection.is_empty());
    assert!(sim.ctx.tool.active().unwrap().create_drawing_kind().is_some());
    let previous = sim.ctx.document.nodes()[0].id();
    sim.ctx.selection.set_selection([previous]);
    draw(&mut sim, pt(200.0, 200.0));
    assert!(sim.ctx.tool.active().unwrap().create_drawing_kind().is_some());
    assert_eq!(sim.features().len(), 2);
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[previous]);
    assert_eq!(bounds(&sim, 1), Rect::from_ltwh(200.0, 200.0, 100.0, 50.0));

    sim.ctx.set_tool(Box::new(SelectTool::default()));
    assert!(is_select(&sim));
    assert!(sim.ctx.tool.is_locked());
    sim.ctx.set_tool(Box::new(CreateFeatureTool::circle()));
    draw(&mut sim, pt(400.0, 400.0));
    assert!(matches!(sim.features()[2].kind, FeatureKind::Circle(_)));
    assert!(!is_select(&sim));

    sim.ctx.tool.toggle_lock();
    draw(&mut sim, pt(600.0, 600.0));
    assert_eq!(sim.features().len(), 4);
    assert!(is_select(&sim));
    let last = sim.ctx.document.nodes().last().unwrap().id();
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[last]);
}

#[test]
fn click_without_drag_does_not_create_feature() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    sim.down(Point::ZERO);
    sim.up(Point::ZERO);
    assert!(sim.ctx.document.nodes().is_empty());
    assert!(sim.ctx.tool.active().unwrap().create_drawing_kind().is_some());
}

#[test]
fn drag_creates_rectangle_feature() {
    let mut sim = Sim::new();
    let previous = Feature::new(pt(200.0, 200.0), crate::Size::new(50.0, 50.0), FeatureKind::Rectangle(RectangleKind::default()));
    let previous_id = sim.ctx.document.insert(None, previous.into(), None).unwrap();
    sim.ctx.selection.set_selection([previous_id]);
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));

    drag(&mut sim, Point::ZERO, pt(100.0, 100.0), NONE);

    assert_eq!(sim.features().len(), 2);
    let created = sim.features()[1];
    assert!(matches!(created.kind, FeatureKind::Rectangle(_)));
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[created.id]);
    assert!(is_select(&sim));
    assert_eq!(created.local_bounds(), Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
}

#[test]
fn drag_creates_circle_feature() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::circle()));
    drag(&mut sim, Point::ZERO, pt(100.0, 100.0), NONE);
    assert_eq!(sim.features().len(), 1);
    assert!(matches!(sim.features()[0].kind, FeatureKind::Circle(_)));
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[sim.features()[0].id]);
    assert!(is_select(&sim));
    assert_eq!(bounds(&sim, 0), Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
}

#[test]
fn shift_drag_creates_square_rectangle() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    drag(&mut sim, Point::ZERO, pt(100.0, 50.0), SHIFT);
    let b = bounds(&sim, 0);
    assert_eq!(b.width(), b.height());
    assert_eq!(b, Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
}

#[test]
fn shift_drag_creates_square_circle_bounds() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::circle()));
    drag(&mut sim, Point::ZERO, pt(80.0, 140.0), SHIFT);
    let b = bounds(&sim, 0);
    assert_eq!(b.width(), b.height());
    assert!((b.width() - 140.0).abs() < 0.001);
}

#[test]
fn alt_drag_creates_rectangle_from_center() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    drag(&mut sim, pt(50.0, 50.0), pt(100.0, 80.0), ALT);
    assert_eq!(bounds(&sim, 0), Rect::from_ltwh(0.0, 20.0, 100.0, 60.0));
}

#[test]
fn alt_shift_drag_creates_square_from_center() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::circle()));
    drag(&mut sim, pt(50.0, 50.0), pt(100.0, 80.0), SHIFT_ALT);
    let b = bounds(&sim, 0);
    assert_eq!(b.width(), b.height());
    assert_eq!(b, Rect::from_ltwh(0.0, 0.0, 100.0, 100.0));
}

#[test]
fn creation_kinds_and_cursor() {
    let sim = Sim::new();
    let tool = CreateFeatureTool::new(FeatureKind::Circle(CircleKind::default()));
    assert!(matches!(tool.create_drawing_kind(), Some(FeatureKind::Circle(_))));
    assert_eq!(tool.resolve_cursor(&sim.ctx, Point::ZERO, &sim.camera), EditorCursor::Crosshair);
}

#[test]
fn preview_paints_while_dragging() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    sim.down(Point::ZERO);
    sim.mv(Point::ZERO);
    sim.mv(pt(40.0, 40.0));
    let mut painter = Painter::new();
    sim.ctx.tool.active().unwrap().paint(&sim.ctx, &sim.camera, &mut painter);
    assert!(!painter.commands.is_empty());
}

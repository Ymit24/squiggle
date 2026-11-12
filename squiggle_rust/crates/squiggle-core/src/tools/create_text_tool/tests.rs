use super::*;
use crate::editor::text_edit::{TextEditKind, commit_text_edit};
use crate::text_sizing::TextSizing;
use crate::tools::test_util::*;

fn draft(sim: &Sim) -> crate::Feature {
    match &sim.ctx.text_edit.session().expect("open text edit").kind {
        TextEditKind::Create { draft } => draft.clone(),
        TextEditKind::Edit { .. } => panic!("expected a create session"),
    }
}

fn sizing(feature: &crate::Feature) -> TextSizing {
    match &feature.kind {
        FeatureKind::Text(t) => t.sizing,
        _ => panic!("not text"),
    }
}

fn is_select(sim: &Sim) -> bool {
    sim.ctx.tool.active().is_some_and(|t| t.create_drawing_kind().is_none())
}

fn commit(sim: &mut Sim, contents: &str) {
    let select = !sim.ctx.tool.is_locked();
    let ctx = &mut sim.ctx;
    commit_text_edit(
        &mut ctx.document,
        &mut ctx.history,
        &mut ctx.selection,
        &mut ctx.text_edit,
        Some(contents),
        select,
        |f, text| {
            f.set_label(text);
        },
    )
    .unwrap();
}

#[test]
fn resolves_crosshair_cursor() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    let cursor = crate::editor::tool_model::ToolModel::resolve_cursor(&sim.ctx, Point::ZERO, &sim.camera);
    assert_eq!(cursor, EditorCursor::Crosshair);
}

#[test]
fn click_opens_create_text_edit_session_without_adding_feature() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    let click = pt(50.0, 75.0);
    sim.up(click);

    assert!(sim.ctx.document.nodes().is_empty());
    assert!(is_select(&sim));
    let session = sim.ctx.text_edit.session().unwrap();
    assert_eq!(draft(&sim).origin, click);
    assert_eq!(session.initial_contents, "");
    assert_eq!(session.layout.top_left(), click);
    assert!(session.layout.width() < 30.0);
}

#[test]
fn mostly_vertical_drag_creates_auto_width_text() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    let start = pt(50.0, 75.0);
    let end = start + pt(0.3, 80.0);
    sim.down(start);
    sim.mv(end);
    sim.up(end);
    assert_eq!(sizing(&draft(&sim)), TextSizing::Auto);
}

#[test]
fn dragging_sideways_creates_fixed_width_text_at_the_dragged_width() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    let (start, end) = (pt(50.0, 75.0), pt(250.0, 90.0));
    sim.mv(start);
    sim.down(start);
    sim.mv(end);
    sim.up(end);
    let d = draft(&sim);
    assert_eq!(sizing(&d), TextSizing::FixedWidth);
    assert_eq!(d.origin, start);
    assert_eq!(d.width(), 200.0);
}

#[test]
fn drag_rectangle_is_painted_in_world_space() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    sim.down(pt(0.0, 0.0));
    sim.mv(pt(2.0, 0.0));
    let mut painter = Painter::new();
    sim.ctx.tool.active().unwrap().paint(&sim.ctx, &sim.camera, &mut painter);
    assert!(painter.commands.is_empty(), "below the drag threshold");
    sim.mv(pt(100.0, 20.0));
    sim.ctx.tool.active().unwrap().paint(&sim.ctx, &sim.camera, &mut painter);
    assert_eq!(painter.commands.len(), 1);
}

#[test]
fn locked_text_tool_stays_ready_after_submit_and_empty_submit() {
    let mut sim = Sim::new();
    sim.ctx.tool.toggle_lock();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    for submit in [true, false] {
        let click = if submit { pt(50.0, 75.0) } else { pt(150.0, 175.0) };
        sim.up(click);
        assert_eq!(draft(&sim).origin, click);
        assert!(!is_select(&sim));
        commit(&mut sim, if submit { "hello" } else { "" });
        assert!(!is_select(&sim));
        assert!(sim.ctx.text_edit.session().is_none());
    }
    assert_eq!(sim.features().len(), 1);
    assert!(sim.ctx.selection.is_empty());
}

#[test]
fn document_unchanged_until_the_edit_commits() {
    let mut sim = Sim::new();
    sim.ctx.set_tool(Box::new(CreateTextTool::new()));
    sim.up(pt(50.0, 75.0));
    assert!(sim.ctx.document.nodes().is_empty());
    commit(&mut sim, "hello");
    assert_eq!(sim.features().len(), 1);
    let created = sim.features()[0];
    assert_eq!(sim.ctx.selection.selected_node_ids(), &[created.id]);
    assert_eq!(created.kind.label(), Some("hello"));
}

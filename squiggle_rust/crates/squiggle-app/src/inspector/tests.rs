//! Headless Rune tests of the inspector (ports of the Dart widget tests
//! `brush_inspector`, `brush_wheel`, `fill_type_inspector`, `stroke_type_inspector` and
//! `text_auto_width_action`).

use super::brush_wheel::{host, label_parts};
use super::brush_ops;
use super::fill_type_selector::fill_type_selector;
use super::stroke_type_selector::stroke_type_selector;
use super::{overlays, panel};
use crate::state::State;
use rune::{Cx, El, Env, Runtime, el};
use squiggle_core::brush_wheel_geometry as geo;
use squiggle_core::feature::Feature;
use squiggle_core::feature_kind::FeatureKind;
use squiggle_core::feature_kinds::{CircleKind, PolylineKind, RectangleKind};
use squiggle_core::fill_type::FillType;
use squiggle_core::geom::{Point, Size};
use squiggle_core::ids::NodeId;
use squiggle_core::session::{BrushProfile, SCRATCH_ID};
use squiggle_core::stroke_type::StrokeType;
use squiggle_core::tools::create_feature_tool::CreateFeatureTool;
use std::sync::atomic::{AtomicUsize, Ordering};

fn view(s: &State, _cx: &mut Cx<State>) -> El {
    el().w_full().h_full().child(panel(s)).child(overlays(s))
}

fn new_state() -> State {
    static N: AtomicUsize = AtomicUsize::new(0);
    let dir = std::env::temp_dir().join(format!("squiggle-inspector-test-{}-{}", std::process::id(), N.fetch_add(1, Ordering::SeqCst)));
    let mut s = State::new(dir);
    s.ctx.viewport_size = Size::new(1100.0, 760.0);
    s
}

fn runtime(state: State) -> Runtime<State> {
    let mut rt = Runtime::new(state, view, (1100.0, 760.0), Env { system_dark: true, scale: 1.0 });
    rt.frame(1.0 / 60.0);
    rt
}

fn settle(rt: &mut Runtime<State>) {
    // Tests mutate the state directly; the view re-reads it on the next frame.
    rt.invalidate();
    for _ in 0..30 {
        rt.frame(1.0 / 60.0);
    }
}

fn click(rt: &mut Runtime<State>, key: &str) {
    let (x, y) = rt.find(key).unwrap_or_else(|| panic!("no element {key}"));
    rt.pointer_move(x, y);
    rt.pointer_down(x, y);
    rt.pointer_up(x, y);
    settle(rt);
}

fn has(rt: &Runtime<State>, key: &str) -> bool {
    rt.find(key).is_some()
}

fn text_shown(rt: &Runtime<State>, content: &str) -> bool {
    rt.elements().iter().any(|e| e.text.as_deref() == Some(content))
}

/// Whether the swatches `{prefix}-0..n` are active, in order.
fn active_flags(rt: &Runtime<State>, prefix: &str, n: usize) -> Vec<bool> {
    let elements = rt.elements();
    (0..n)
        .map(|i| {
            let key = format!("{prefix}-{i}");
            elements.iter().find(|e| e.key.as_deref() == Some(key.as_str())).unwrap_or_else(|| panic!("{key}")).item_selected
        })
        .collect()
}

fn add(s: &mut State, kind: FeatureKind) -> NodeId {
    let feature = Feature::new(Point::new(0.0, 0.0), Size::new(100.0, 60.0), kind);
    s.ctx.document.insert(None, feature.into(), None).unwrap()
}

fn line() -> FeatureKind {
    FeatureKind::Polyline(PolylineKind::new(vec![Point::ZERO, Point::new(100.0, 0.0)]))
}

fn select(s: &mut State, ids: &[NodeId]) {
    s.ctx.selection.set_selection(ids.iter().copied());
}

fn fill_types(s: &State, ids: &[NodeId]) -> Vec<Option<FillType>> {
    ids.iter().map(|&id| s.ctx.document.feature(id).unwrap().kind.fill_type()).collect()
}

fn stroke_types(s: &State, ids: &[NodeId]) -> Vec<Option<StrokeType>> {
    ids.iter().map(|&id| s.ctx.document.feature(id).unwrap().kind.stroke_type()).collect()
}

fn mixed_selection(s: &mut State) -> [NodeId; 3] {
    let mut circle = CircleKind::default();
    circle.style.fill_type = FillType::Lines;
    circle.style.stroke_type = StrokeType::Dotted;
    let mut dashed = PolylineKind::new(vec![Point::ZERO, Point::new(100.0, 0.0)]);
    dashed.stroke_type = StrokeType::Dashed;
    let ids = [
        add(s, FeatureKind::Rectangle(RectangleKind::default())),
        add(s, FeatureKind::Circle(circle)),
        add(s, FeatureKind::Polyline(dashed)),
    ];
    select(s, &ids);
    ids
}

// --- fill_type_inspector_test ---

#[test]
fn selection_fill_choices_support_undo_without_changing_new_shape_styles() {
    let mut s = new_state();
    let ids = mixed_selection(&mut s);
    for id in ids {
        s.ctx.document.feature_mut(id).unwrap().kind.set_fill_type(FillType::Solid);
    }
    s.ctx.document.feature_mut(ids[1]).unwrap().kind.set_fill_type(FillType::Lines);
    let mut rt = runtime(s);

    assert_eq!(active_flags(&rt, "fillType", 3), [false, false, false]);
    for (index, ty) in FillType::ALL.iter().enumerate() {
        click(&mut rt, &format!("fillType-{index}"));
        assert_eq!(&fill_types(&rt.state, &ids[..2]), &[Some(*ty), Some(*ty)]);
    }
    rt.state.ctx.undo();
    assert_eq!(fill_types(&rt.state, &ids[..2]), [Some(FillType::Lines), Some(FillType::Lines)]);
    rt.state.ctx.redo();
    assert_eq!(fill_types(&rt.state, &ids[..2]), [Some(FillType::Crosshatch), Some(FillType::Crosshatch)]);

    // The brush that styles new shapes is untouched.
    assert!(rt.state.ctx.document.session.active_brush().values.is_empty());
    let mut rect = FeatureKind::Rectangle(RectangleKind::default());
    rt.state.ctx.apply_active_brush(&mut rect);
    assert_eq!(rect.fill_type(), Some(FillType::Solid));
    let line_kind = &rt.state.ctx.document.feature(ids[2]).unwrap().kind;
    assert!(line_kind.inspector_fields().iter().all(|f| f.key != "fillType"));
}

// --- stroke_type_inspector_test ---

#[test]
fn stroke_selector_shows_the_active_type_and_selects_each_option() {
    fn selector_view(_s: &State, _cx: &mut Cx<State>) -> El {
        stroke_type_selector("t", Some(StrokeType::Dashed), false, true, |s, ty| {
            s.ctx.camera.zoom = 1.0 + StrokeType::ALL.iter().position(|t| *t == ty).unwrap() as f64;
        })
    }
    let mut rt = Runtime::new(new_state(), selector_view, (400.0, 100.0), Env { system_dark: true, scale: 1.0 });
    rt.frame(0.0);
    assert_eq!(active_flags(&rt, "t", 3), [false, true, false]);
    for index in 0..3 {
        click(&mut rt, &format!("t-{index}"));
        assert_eq!(rt.state.ctx.camera.zoom, 1.0 + index as f64);
    }
}

#[test]
fn mixed_selection_has_no_active_swatch_and_disabled_ignores_presses() {
    fn selector_view(_s: &State, _cx: &mut Cx<State>) -> El {
        stroke_type_selector("t", Some(StrokeType::Solid), true, false, |s, _| s.ctx.camera.zoom = 9.0)
    }
    let mut rt = Runtime::new(new_state(), selector_view, (400.0, 100.0), Env { system_dark: true, scale: 1.0 });
    rt.frame(0.0);
    assert_eq!(active_flags(&rt, "t", 3), [false, false, false]);
    click(&mut rt, "t-1");
    assert_eq!(rt.state.ctx.camera.zoom, 1.0);
}

#[test]
fn fill_selector_marks_the_active_type() {
    fn selector_view(_s: &State, _cx: &mut Cx<State>) -> El {
        fill_type_selector("f", Some(FillType::Lines), false, true, |_, _| {})
    }
    let mut rt = Runtime::new(new_state(), selector_view, (400.0, 100.0), Env { system_dark: true, scale: 1.0 });
    rt.frame(0.0);
    assert_eq!(active_flags(&rt, "f", 3), [false, true, false]);
}

#[test]
fn selection_inspector_updates_mixed_shapes_without_changing_drawing_defaults() {
    let mut s = new_state();
    let ids = mixed_selection(&mut s);
    let mut rt = runtime(s);

    assert_eq!(active_flags(&rt, "strokeType", 3), [false, false, false]);
    click(&mut rt, "strokeType-2");
    assert_eq!(stroke_types(&rt.state, &ids), [Some(StrokeType::Dotted); 3]);
    assert_eq!(active_flags(&rt, "strokeType", 3), [false, false, true]);

    rt.state.ctx.undo();
    assert_eq!(stroke_types(&rt.state, &ids), [Some(StrokeType::Solid), Some(StrokeType::Dotted), Some(StrokeType::Dashed)]);
    rt.state.ctx.redo();
    assert_eq!(stroke_types(&rt.state, &ids), [Some(StrokeType::Dotted); 3]);
    assert!(rt.state.ctx.document.session.active_brush().values.is_empty());
}

#[test]
fn picking_a_colour_edits_the_selection_as_one_undoable_entry() {
    let mut s = new_state();
    let ids = [add(&mut s, FeatureKind::Rectangle(RectangleKind::default())), add(&mut s, line())];
    select(&mut s, &ids);
    let mut rt = runtime(s);
    click(&mut rt, "strokeColor-1");
    let expected = squiggle_core::document_colors::STYLE_PRESETS[1].stroke_color;
    for id in ids {
        assert_eq!(rt.state.ctx.document.feature(id).unwrap().kind.stroke_color(), Some(expected));
    }
    rt.state.ctx.undo();
    for id in ids {
        assert_ne!(rt.state.ctx.document.feature(id).unwrap().kind.stroke_color(), Some(expected));
    }
    assert!(!rt.state.ctx.history.can_undo());
}

// --- text_auto_width_action_test ---

#[test]
fn auto_width_applies_only_to_fixed_width_text_and_is_undoable() {
    let mut s = new_state();
    let fixed = s.ctx.new_text_feature(Point::ZERO, "hello", Some(300.0));
    let auto = s.ctx.new_text_feature(Point::ZERO, "hello", None);
    let rect = Feature::new(Point::ZERO, Size::new(10.0, 10.0), FeatureKind::Rectangle(RectangleKind::default()));
    assert!(super::text_auto_width_action::applies_to(&[&fixed]));
    assert!(!super::text_auto_width_action::applies_to(&[&fixed, &auto]));
    assert!(!super::text_auto_width_action::applies_to(&[&fixed, &rect]));
    assert!(!super::text_auto_width_action::applies_to(&[]));

    let id = s.ctx.document.insert(None, fixed.into(), None).unwrap();
    select(&mut s, &[id]);
    let mut rt = runtime(s);
    click(&mut rt, "auto-width");
    let sizing = |s: &State| match &s.ctx.document.feature(id).unwrap().kind {
        FeatureKind::Text(t) => t.sizing,
        _ => panic!("text"),
    };
    assert_eq!(sizing(&rt.state), squiggle_core::text_sizing::TextSizing::Auto);
    assert!(rt.state.ctx.document.feature(id).unwrap().size.width < 300.0);

    rt.state.ctx.undo();
    assert_eq!(sizing(&rt.state), squiggle_core::text_sizing::TextSizing::FixedWidth);
    assert_eq!(rt.state.ctx.document.feature(id).unwrap().size.width, 300.0);
}

// --- brush_inspector_test ---

fn drawing_state() -> State {
    let mut s = new_state();
    s.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    s
}

fn active_name(rt: &Runtime<State>) -> String {
    rt.state.ctx.document.session.active_brush().name.clone()
}

fn brush_ids(rt: &Runtime<State>) -> Vec<String> {
    rt.state.ctx.document.session.brushes.iter().map(|b| b.id.clone()).collect()
}

fn create(s: &mut State, name: &str) -> BrushProfile {
    brush_ops::create(&mut s.ctx, name).unwrap()
}

#[test]
fn drawing_edits_change_the_brush_while_selected_edits_and_undo_leave_it_alone() {
    let mut rt = runtime(drawing_state());
    assert!(has(&rt, "brush-picker-trigger"));

    click(&mut rt, "strokeWidth-0");
    assert_eq!(rt.state.ctx.document.session.active_brush().values["strokeWidth"], serde_json::json!(3.0));
    assert!(!rt.state.ctx.history.can_undo());
    assert!(has(&rt, "reset-strokeWidth"));
    click(&mut rt, "reset-strokeWidth");
    assert!(rt.state.ctx.document.session.active_brush().values.is_empty());

    let id = add(&mut rt.state, FeatureKind::Rectangle(RectangleKind::default()));
    select(&mut rt.state, &[id]);
    settle(&mut rt);
    assert!(!has(&rt, "brush-picker-trigger"));
    click(&mut rt, "strokeWidth-2");
    assert_eq!(rt.state.ctx.document.feature(id).unwrap().kind.stroke_width(), Some(16.0));
    assert!(rt.state.ctx.document.session.active_brush().values.is_empty());
    assert!(!has(&rt, "reset-strokeWidth"));
    rt.state.ctx.undo();
    assert_eq!(rt.state.ctx.document.feature(id).unwrap().kind.stroke_width(), Some(8.0));

    rt.state.ctx.selection.clear_selection();
    rt.state.ctx.reset_to_select_tool();
    settle(&mut rt);
    assert!(!has(&rt, "brush-picker-trigger") && !has(&rt, "strokeWidth-0"));
    rt.state.ctx.set_tool(Box::new(CreateFeatureTool::rect()));
    settle(&mut rt);
    assert!(has(&rt, "brush-picker-trigger") && has(&rt, "strokeWidth-0"));
}

#[test]
fn a_small_mouse_movement_still_clicks_the_entry() {
    let mut s = drawing_state();
    let actual = create(&mut s, "Actual");
    let notes = create(&mut s, "Notes");
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    let (x, y) = rt.find(&actual.id).unwrap();
    rt.pointer_move(x, y);
    rt.pointer_down(x, y);
    rt.pointer_move(x + 0.5, y + 0.5);
    rt.frame(0.016);
    assert_eq!(rt.state.ctx.document.session.active_brush().id, notes.id);
    rt.pointer_up(x + 0.5, y + 0.5);
    settle(&mut rt);
    assert_eq!(active_name(&rt), "Actual");
    assert_eq!(brush_ids(&rt), [SCRATCH_ID.to_owned(), actual.id.clone(), notes.id.clone()]);
    assert!(!has(&rt, "brush-dropdown"));
}

fn drag(rt: &mut Runtime<State>, from_key: &str, rows: f32) {
    let (x, y) = rt.find(from_key).unwrap();
    rt.pointer_move(x, y);
    rt.pointer_down(x, y);
    rt.pointer_move(x, y - 8.0 * rows.signum());
    rt.frame(0.016);
    rt.pointer_move(x, y + rows * super::metrics::BRUSH_ENTRY_HEIGHT);
    rt.frame(0.016);
    rt.pointer_up(x, y + rows * super::metrics::BRUSH_ENTRY_HEIGHT);
    settle(rt);
}

#[test]
fn entry_drag_commits_on_drop_without_selecting_or_closing_the_menu() {
    let mut s = drawing_state();
    let actual = create(&mut s, "Actual");
    let construction = create(&mut s, "Construction");
    let notes = create(&mut s, "Notes");
    brush_ops::activate(&mut s.ctx, &actual.id);
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    assert!(!has(&rt, "brush-drag-scratch"));

    drag(&mut rt, &format!("brush-drag-{}", notes.id), -2.0);
    assert_eq!(brush_ids(&rt), [SCRATCH_ID.to_owned(), notes.id.clone(), actual.id.clone(), construction.id.clone()]);
    assert_eq!(rt.state.ctx.document.session.active_brush().id, actual.id);
    assert!(has(&rt, "brush-dropdown"));
    for id in brush_ids(&rt) {
        assert!(has(&rt, &id), "{id} stays mounted");
    }
    assert!(text_shown(&rt, "\u{2318}3"));

    click(&mut rt, &notes.id);
    assert_eq!(active_name(&rt), "Notes");
    assert!(!has(&rt, "brush-dropdown"));
}

#[test]
fn a_cancelled_drag_leaves_the_order_unchanged() {
    let mut s = drawing_state();
    let actual = create(&mut s, "Actual");
    let notes = create(&mut s, "Notes");
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    // Dropping within the row's own slot is a no-op that neither selects nor closes.
    drag(&mut rt, &format!("brush-drag-{}", notes.id), 0.4);
    assert_eq!(brush_ids(&rt), [SCRATCH_ID.to_owned(), actual.id, notes.id]);
    assert!(has(&rt, "brush-dropdown"));
}

#[test]
fn nine_brushes_disable_create_until_a_brush_is_deleted() {
    let mut s = drawing_state();
    for i in 1..9 {
        create(&mut s, &format!("Brush {i}"));
    }
    assert!(brush_ops::create(&mut s.ctx, "Overflow").is_err());
    let last = s.ctx.document.session.active_brush().id.clone();
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    assert!(text_shown(&rt, "\u{2318}1") && text_shown(&rt, "\u{2318}9"));
    click(&mut rt, "brush-create");
    assert!(!has(&rt, "brush-name-field"), "create is disabled at nine brushes");

    brush_ops::delete(&mut rt.state.ctx, &last);
    settle(&mut rt);
    click(&mut rt, "brush-create");
    assert!(has(&rt, "brush-name-field"));
}

#[test]
fn creating_from_the_picker_copies_active_values_and_switching_restores_them() {
    let mut s = drawing_state();
    brush_ops::set_field(&mut s.ctx, "strokeColor", serde_json::json!(0xFFFF_A500u32));
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    click(&mut rt, "brush-create");
    rt.state.inspector_ui.name_edit.replace_text("Construction");
    settle(&mut rt);
    click(&mut rt, "brush-name-submit");
    assert_eq!(active_name(&rt), "Construction");
    assert_eq!(
        serde_json::Value::Object(rt.state.ctx.document.session.active_brush().values.clone()),
        serde_json::json!({ "strokeColor": 0xFFFF_A500u32 })
    );

    brush_ops::set_field(&mut rt.state.ctx, "strokeWidth", serde_json::json!(3.0));
    settle(&mut rt);
    click(&mut rt, "brush-picker-trigger");
    click(&mut rt, SCRATCH_ID);
    assert_eq!(
        serde_json::Value::Object(rt.state.ctx.document.session.active_brush().values.clone()),
        serde_json::json!({ "strokeColor": 0xFFFF_A500u32 })
    );
    assert!(!has(&rt, "brush-actions-trigger"));
}

#[test]
fn an_empty_name_cannot_be_submitted_and_cancel_closes_the_dialog() {
    let mut rt = runtime(drawing_state());
    click(&mut rt, "brush-picker-trigger");
    click(&mut rt, "brush-create");
    click(&mut rt, "brush-name-submit");
    assert!(has(&rt, "brush-name-field"));
    assert_eq!(rt.state.ctx.document.session.brushes.len(), 1);
    click(&mut rt, "brush-name-cancel");
    assert!(!has(&rt, "brush-name-field"));
}

#[test]
fn picker_and_management_menu_exclude_each_other_and_rename_and_delete_work() {
    let mut s = drawing_state();
    create(&mut s, "Actual");
    let mut rt = runtime(s);
    click(&mut rt, "brush-picker-trigger");
    assert!(has(&rt, "brush-dropdown"));
    click(&mut rt, "brush-actions-trigger");
    assert!(!has(&rt, "brush-dropdown") && has(&rt, "brush-rename"));

    click(&mut rt, "brush-rename");
    rt.state.inspector_ui.name_edit.replace_text("Actual geometry");
    settle(&mut rt);
    click(&mut rt, "brush-name-submit");
    assert_eq!(active_name(&rt), "Actual geometry");

    brush_ops::set_field(&mut rt.state.ctx, "strokeWidth", serde_json::json!(8.0));
    let id = rt.state.ctx.document.session.active_brush().id.clone();
    click(&mut rt, "brush-actions-trigger");
    click(&mut rt, "brush-delete");
    click(&mut rt, "brush-delete-confirm");
    assert!(rt.state.ctx.document.session.active_brush().is_scratch());
    assert!(rt.state.ctx.document.session.brushes.iter().all(|b| b.id != id));
    assert_eq!(rt.state.ctx.document.session.active_brush().values["strokeWidth"], serde_json::json!(8.0));
    assert!(!has(&rt, "brush-actions-trigger"));
    assert!(!rt.state.ctx.history.can_undo());
}

// --- layout actions ---

fn rect_at(s: &mut State, x: f64) -> NodeId {
    let f = Feature::new(Point::new(x, x / 2.0), Size::new(10.0, 10.0), FeatureKind::Rectangle(RectangleKind::default()));
    s.ctx.document.insert(None, f.into(), None).unwrap()
}

#[test]
fn align_needs_two_nodes_distribute_three_and_each_is_one_undo() {
    let mut s = new_state();
    let a = rect_at(&mut s, 0.0);
    let b = rect_at(&mut s, 30.0);
    select(&mut s, &[a, b]);
    // Tall enough that the whole panel is visible without scrolling.
    s.ctx.viewport_size = Size::new(1100.0, 2000.0);
    let mut rt = Runtime::new(s, view, (1100.0, 2000.0), Env { system_dark: true, scale: 1.0 });
    rt.frame(1.0 / 60.0);
    assert!(has(&rt, "align-left") && !has(&rt, "distribute-horizontal"));
    click(&mut rt, "align-left");
    let x = |rt: &Runtime<State>, id| rt.state.ctx.document.node(id).unwrap().origin().x;
    assert_eq!(x(&rt, b), 0.0);
    rt.state.ctx.undo();
    assert_eq!(x(&rt, b), 30.0);

    let c = rect_at(&mut rt.state, 100.0);
    select(&mut rt.state, &[a, b, c]);
    settle(&mut rt);
    assert!(has(&rt, "distribute-horizontal"));
    click(&mut rt, "distribute-horizontal");
    assert_eq!(x(&rt, b), 50.0);
}

// --- brush_wheel_test ---

const POINTER: Point = Point::new(700.0, 450.0);

/// Rect tool with Scratch, Ink (active) and Blueprint.
fn wheel_state() -> State {
    let mut s = drawing_state();
    let ink = create(&mut s, "Ink");
    create(&mut s, "Blueprint");
    brush_ops::activate(&mut s.ctx, &ink.id);
    s.inspector_ui.pointer = Some(POINTER);
    s
}

fn slot(rt: &Runtime<State>, index: usize) -> Point {
    let session = &rt.state.ctx.document.session;
    POINTER + geo::slot_center(index, session.brushes.len() + usize::from(session.can_create_brush()))
}

fn hovered(rt: &Runtime<State>) -> Option<usize> {
    rt.state.inspector_ui.wheel.as_ref().and_then(|w| w.hovered)
}

fn move_to(rt: &mut Runtime<State>, p: Point) {
    rt.pointer_move(p.x as f32, p.y as f32);
    settle(rt);
}

fn move_to_slot(rt: &mut Runtime<State>, index: usize) {
    let p = slot(rt, index);
    move_to(rt, p);
}

fn open_wheel(rt: &mut Runtime<State>) {
    assert!(host::open(&mut rt.state, false));
    settle(rt);
}

fn release(rt: &mut Runtime<State>, commit: bool) {
    host::close(&mut rt.state, commit);
    settle(rt);
}

#[test]
fn holding_b_opens_the_wheel_and_releasing_activates_the_hovered_brush() {
    let mut rt = runtime(wheel_state());
    open_wheel(&mut rt);
    assert!(has(&rt, "brush-wheel"));
    assert!(text_shown(&rt, "Release to cancel"));

    move_to_slot(&mut rt, 2);
    assert_eq!(hovered(&rt), Some(2));

    release(&mut rt, true);
    assert!(!has(&rt, "brush-wheel"));
    assert_eq!(active_name(&rt), "Blueprint");
}

#[test]
fn releasing_on_the_add_slot_opens_the_name_dialog() {
    let mut rt = runtime(wheel_state());
    open_wheel(&mut rt);
    move_to_slot(&mut rt, 3);
    assert!(text_shown(&rt, "New brush\u{2026}"));
    release(&mut rt, true);
    assert!(!has(&rt, "brush-wheel"));
    assert!(has(&rt, "brush-name-field"));
}

#[test]
fn the_add_slot_is_hidden_at_nine_brushes() {
    let mut s = wheel_state();
    while s.ctx.document.session.can_create_brush() {
        create(&mut s, "Extra");
    }
    let mut rt = runtime(s);
    open_wheel(&mut rt);
    assert!(has(&rt, "brush-wheel") && !has(&rt, "brush-wheel-add"));
}

#[test]
fn releasing_in_the_hub_or_outside_the_wheel_changes_nothing() {
    let mut rt = runtime(wheel_state());
    for target in [POINTER, POINTER + Point::new(0.0, -200.0)] {
        open_wheel(&mut rt);
        move_to_slot(&mut rt, 0);
        move_to(&mut rt, target);
        assert_eq!(hovered(&rt), None);
        release(&mut rt, true);
        assert_eq!(active_name(&rt), "Ink");
        rt.state.inspector_ui.pointer = Some(POINTER);
    }
}

#[test]
fn releasing_on_the_active_brush_keeps_it_without_notifying() {
    let mut rt = runtime(wheel_state());
    let before = rt.state.ctx.brushes.revision();
    open_wheel(&mut rt);
    move_to_slot(&mut rt, 1);
    assert!(text_shown(&rt, " \u{b7} current"));
    release(&mut rt, true);
    assert_eq!(active_name(&rt), "Ink");
    assert_eq!(rt.state.ctx.brushes.revision(), before);
}

#[test]
fn escape_cancels_the_wheel() {
    let mut rt = runtime(wheel_state());
    open_wheel(&mut rt);
    move_to_slot(&mut rt, 2);
    release(&mut rt, false);
    assert!(!has(&rt, "brush-wheel"));
    assert_eq!(active_name(&rt), "Ink");
}

#[test]
fn the_wheel_stays_closed_without_a_drawing_tool_or_with_a_selection_or_modifier() {
    let mut s = wheel_state();
    assert!(!host::can_open(&s, true));
    let id = add(&mut s, FeatureKind::Rectangle(RectangleKind::default()));
    select(&mut s, &[id]);
    assert!(!host::can_open(&s, false));
    s.ctx.selection.clear_selection();
    s.ctx.reset_to_select_tool();
    let mut rt = runtime(s);
    assert!(!host::open(&mut rt.state, false));
    assert!(!has(&rt, "brush-wheel"));
}

#[test]
fn the_wheel_is_clamped_inside_the_viewport() {
    let mut s = wheel_state();
    s.inspector_ui.pointer = Some(Point::new(0.0, 0.0));
    let mut rt = runtime(s);
    open_wheel(&mut rt);
    let c = rt.state.inspector_ui.wheel.as_ref().unwrap().center;
    assert!(c.x >= geo::OUTER_RADIUS && c.y >= geo::OUTER_RADIUS);
}

#[test]
fn label_text_names_the_pending_change() {
    let ink = BrushProfile::new("a", "Ink");
    let blue = BrushProfile::new("b", "Blueprint");
    assert_eq!(label_parts(&ink, None, false), [("Release to cancel".to_owned(), true)]);
    assert_eq!(label_parts(&ink, Some(&ink), false)[1], (" \u{b7} current".to_owned(), true));
    assert_eq!(label_parts(&ink, Some(&blue), false), [("Ink \u{2192} ".to_owned(), true), ("Blueprint".to_owned(), false)]);
    assert_eq!(label_parts(&ink, None, true), [("New brush\u{2026}".to_owned(), false)]);
}

//! Ports of `test/tools/select_tool/*` and `test/tools/select_tool_test.dart`.

use super::resize_handle_util::resize_handles;
use super::selection_resize_handle::SelectionResizeHandle as H;
use super::*;
use crate::document::Document;
use crate::editor::text_edit::TextEditKind;
use crate::editor::tool_model::ToolModel;
use crate::feature::Feature;
use crate::feature_geometry::world_points;
use crate::feature_kind::FeatureKind;
use crate::feature_kinds::{CircleKind, PolylineKind, RectangleKind, ShapeStyle, TextKind};
use crate::geom::{Rect, Size};
use crate::group::Group;
use crate::node::Node;
use crate::text_feature_placement::new_text_feature_at;
use crate::text_sizing::TextSizing;

const NONE: Modifiers = Modifiers { shift: false, alt: false, command: false };
const SHIFT: Modifiers = Modifiers { shift: true, alt: false, command: false };
const ALT: Modifiers = Modifiers { shift: false, alt: true, command: false };
const COMMAND: Modifiers = Modifiers { shift: false, alt: false, command: true };
const COMMAND_SHIFT: Modifiers = Modifiers { shift: true, alt: false, command: true };

fn p(x: f64, y: f64) -> Point {
    Point::new(x, y)
}

fn rect_feature(x: f64, y: f64, w: f64, h: f64) -> Node {
    Feature::new(p(x, y), Size::new(w, h), FeatureKind::default()).into()
}

fn polyline_feature(x: f64, points: Vec<Point>, size: Size) -> Node {
    Feature::new(p(x, 0.0), size, FeatureKind::Polyline(PolylineKind::new(points))).into()
}

#[derive(Clone, Copy)]
enum Edge {
    Top,
    Right,
    Bottom,
    Left,
}

struct Harness {
    ctx: EditorContext,
    camera: Camera,
}

impl Harness {
    fn new() -> Self {
        Self::with_nodes(vec![rect_feature(0.0, 0.0, 100.0, 100.0), rect_feature(200.0, 0.0, 100.0, 100.0)])
    }

    fn with_nodes(nodes: Vec<Node>) -> Self {
        Self::with_document(Document::from_nodes(nodes))
    }

    fn with_document(doc: Document) -> Self {
        Harness { ctx: EditorContext::new(doc), camera: Camera::default() }
    }

    fn polyline() -> Self {
        let line = polyline_feature(0.0, vec![Point::ZERO, p(100.0, 100.0)], Size::new(100.0, 100.0));
        Self::with_nodes(vec![line])
    }

    fn down(&mut self, w: Point, m: Modifiers) {
        ToolModel::on_pointer_down(&mut self.ctx, w, &self.camera, m);
    }

    fn mv(&mut self, w: Point, m: Modifiers) {
        ToolModel::on_pointer_move(&mut self.ctx, w, &self.camera, m);
    }

    fn up(&mut self, w: Point, m: Modifiers) {
        ToolModel::on_pointer_up(&mut self.ctx, w, &self.camera, m);
    }

    fn click(&mut self, w: Point, m: Modifiers) {
        self.down(w, m);
        self.up(w, m);
    }

    fn double_click(&mut self, w: Point) {
        self.click(w, NONE);
        ToolModel::on_double_click(&mut self.ctx, w, &self.camera);
    }

    fn key(&mut self, key: Key, mods: Modifiers) -> bool {
        ToolModel::on_key(&mut self.ctx, KeyInput { key, mods })
    }

    fn undo(&mut self) {
        self.ctx.history.undo(&mut self.ctx.document).unwrap();
    }

    fn redo(&mut self) {
        self.ctx.history.redo(&mut self.ctx.document).unwrap();
    }

    fn id(&self, index: usize) -> NodeId {
        self.ctx.document.nodes()[index].id()
    }

    fn ids(&self) -> Vec<NodeId> {
        self.ctx.document.nodes().iter().map(Node::id).collect()
    }

    fn selection(&self) -> Vec<NodeId> {
        self.ctx.selection.selected_node_ids().to_vec()
    }

    fn select(&mut self, ids: impl IntoIterator<Item = NodeId>) {
        self.ctx.selection.set_selection(ids);
    }

    fn node(&self, id: NodeId) -> &Node {
        self.ctx.document.node(id).unwrap()
    }

    fn feature(&self, id: NodeId) -> &Feature {
        self.ctx.document.feature(id).unwrap()
    }

    fn origin(&self, id: NodeId) -> Point {
        self.node(id).origin()
    }

    fn bounds(&self, id: NodeId) -> Rect {
        self.node(id).local_bounds()
    }

    fn text(&self, id: NodeId) -> &TextKind {
        match &self.feature(id).kind {
            FeatureKind::Text(k) => k,
            other => panic!("not text: {other:?}"),
        }
    }

    fn polyline_points(&self, id: NodeId) -> Vec<Point> {
        match &self.feature(id).kind {
            FeatureKind::Polyline(k) => world_points(self.feature(id).origin, &k.local_points),
            other => panic!("not polyline: {other:?}"),
        }
    }

    fn json(&self) -> serde_json::Value {
        self.ctx.document.to_json()
    }

    fn corner_hit(&self, bounds: Rect) -> Point {
        let selection = bounds.inflate(SELECTION_BOX_PADDING);
        let radius = self.camera.screen_length_to_world_length(SELECTION_HANDLE_HIT_SIZE / 2.0);
        selection.bottom_right() + p(radius, radius)
    }

    fn edge_hit(&self, bounds: Rect, edge: Edge) -> Point {
        let screen = self.camera.world_to_screen_bounds(bounds).inflate(SELECTION_BOX_PADDING);
        let half = SELECTION_HANDLE_HIT_SIZE / 2.0;
        let c = screen.center();
        let point = match edge {
            Edge::Top => p(c.x, screen.top - half),
            Edge::Right => p(screen.right - half, c.y),
            Edge::Bottom => p(c.x, screen.bottom - half),
            Edge::Left => p(screen.left - half, c.y),
        };
        self.camera.screen_to_world(point)
    }

    fn handle_center(&self, id: NodeId, handle: H) -> Point {
        let handles = resize_handles(self.node(id), &self.camera);
        handles.iter().find(|h| h.handle == handle).unwrap().geometry.center()
    }
}

fn close(a: f64, b: f64) {
    assert!((a - b).abs() < 1e-3, "{a} != {b}");
}

fn first_selected(h: &mut Harness) -> NodeId {
    let id = h.id(0);
    h.ctx.selection.select_node(id);
    id
}

// --- SelectTool -----------------------------------------------------------------------------

#[test]
fn is_the_active_editor_tool_by_default() {
    let h = Harness::new();
    assert!(h.ctx.tool.active().is_some());
    assert_eq!(h.ctx.tool.active().unwrap().id(), ToolId::Select);
}

#[test]
fn deactivation_cancels_an_interaction_and_clears_selection() {
    let mut h = Harness::new();
    let id = h.id(0);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(70.0, 80.0), NONE);
    assert_eq!(h.origin(id), p(20.0, 30.0));

    ToolModel::with_active(&mut h.ctx, |t, c| t.deactivate(c));

    assert_eq!(h.origin(id), Point::ZERO);
    assert!(h.selection().is_empty());
    assert!(!h.ctx.history.is_active());
    assert!(!h.ctx.history.can_undo());
}

// --- BoxSelectionState ----------------------------------------------------------------------

#[test]
fn marquee_selects_nodes_intersecting_it() {
    let mut h = Harness::new();
    h.down(p(-20.0, -20.0), NONE);
    h.mv(p(120.0, 120.0), NONE);
    h.up(p(120.0, 120.0), NONE);
    assert_eq!(h.selection(), vec![h.id(0)]);
}

#[test]
fn marquee_updates_selection_as_it_changes() {
    let mut h = Harness::new();
    h.down(p(-20.0, -20.0), NONE);
    h.mv(p(320.0, 120.0), NONE);
    assert_eq!(h.selection().len(), 2);
    h.mv(p(120.0, 120.0), NONE);
    assert_eq!(h.selection(), vec![h.id(0)]);
}

#[test]
fn shift_marquee_adds_to_existing_selection() {
    let mut h = Harness::new();
    h.ctx.selection.select_node(h.id(0));
    h.down(p(180.0, -20.0), SHIFT);
    h.mv(p(320.0, 120.0), SHIFT);
    h.up(p(320.0, 120.0), SHIFT);
    assert_eq!(h.selection(), vec![h.id(0), h.id(1)]);
}

#[test]
fn marquee_notifies_the_tool_and_paints_overlay() {
    let mut h = Harness::new();
    let before = h.ctx.tool.revision();
    h.down(p(500.0, 500.0), NONE);
    h.mv(p(600.0, 600.0), NONE);
    assert!(h.ctx.tool.revision() > before);
    assert!(h.ctx.tool.active().is_some());

    let mut painter = Painter::new();
    h.ctx.tool.active().unwrap().paint(&h.ctx, &h.camera, &mut painter);
    assert!(!painter.commands.is_empty());
}

// --- ClickCanvasState -----------------------------------------------------------------------

#[test]
fn empty_click_clears_selection() {
    let mut h = Harness::new();
    h.select([h.id(0)]);
    h.click(p(500.0, 500.0), NONE);
    assert!(h.selection().is_empty());
}

#[test]
fn shift_click_on_empty_canvas_preserves_selection() {
    let mut h = Harness::new();
    h.select([h.id(0)]);
    h.click(p(500.0, 500.0), SHIFT);
    assert_eq!(h.selection(), vec![h.id(0)]);
}

// --- ClickNodeState -------------------------------------------------------------------------

#[test]
fn click_selects_a_node() {
    let mut h = Harness::new();
    h.click(p(50.0, 50.0), NONE);
    assert_eq!(h.selection(), vec![h.id(0)]);
}

#[test]
fn click_switches_selection_to_another_node() {
    let mut h = Harness::new();
    h.click(p(50.0, 50.0), NONE);
    h.click(p(250.0, 50.0), NONE);
    assert_eq!(h.selection(), vec![h.id(1)]);
}

#[test]
fn shift_click_adds_and_removes_nodes() {
    let mut h = Harness::new();
    h.click(p(50.0, 50.0), NONE);
    h.click(p(250.0, 50.0), SHIFT);
    h.click(p(50.0, 50.0), SHIFT);
    assert_eq!(h.selection(), vec![h.id(1)]);
}

#[test]
fn alt_click_without_a_drag_does_not_duplicate() {
    let mut h = Harness::new();
    h.click(p(50.0, 50.0), ALT);
    assert_eq!(h.ctx.document.nodes().len(), 2);
}

// --- DragPolylineHandleState ----------------------------------------------------------------

fn selected_polyline() -> Harness {
    let mut h = Harness::polyline();
    h.click(p(50.0, 50.0), NONE);
    h
}

#[test]
fn drags_a_selected_polyline_vertex() {
    let mut h = selected_polyline();
    let id = h.id(0);
    h.down(p(100.0, 100.0), NONE);
    h.mv(p(150.0, 100.0), NONE);
    h.up(p(150.0, 100.0), NONE);
    assert_eq!(*h.polyline_points(id).last().unwrap(), p(150.0, 100.0));
}

#[test]
fn shift_drag_snaps_a_vertex_to_45_degrees() {
    let mut h = selected_polyline();
    let id = h.id(0);
    h.down(p(100.0, 100.0), NONE);
    h.mv(p(140.0, 120.0), SHIFT);
    h.up(p(140.0, 120.0), SHIFT);
    let last = *h.polyline_points(id).last().unwrap();
    close(last.x, last.y);
}

#[test]
fn vertex_drag_commits_one_undo_entry() {
    let mut h = selected_polyline();
    let id = h.id(0);
    h.down(p(100.0, 100.0), NONE);
    h.mv(p(150.0, 100.0), NONE);
    h.mv(p(175.0, 125.0), NONE);
    assert!(!h.ctx.history.can_undo());

    h.up(p(175.0, 125.0), NONE);
    assert_eq!(*h.polyline_points(id).last().unwrap(), p(175.0, 125.0));

    h.undo();
    assert_eq!(*h.polyline_points(id).last().unwrap(), p(100.0, 100.0));
}

#[test]
fn no_vertex_handles_for_multiple_selections() {
    let line = |x| polyline_feature(x, vec![Point::ZERO, p(100.0, 0.0)], Size::new(100.0, 1.0));
    let mut h = Harness::with_nodes(vec![line(0.0), line(200.0)]);
    let (a, b) = (h.id(0), h.id(1));
    h.select([a, b]);
    let before = h.polyline_points(a);

    h.down(p(100.0, 0.0), NONE);
    h.mv(p(150.0, 20.0), NONE);
    h.up(p(150.0, 20.0), NONE);

    match &h.feature(a).kind {
        FeatureKind::Polyline(k) => assert_eq!(k.local_points, vec![Point::ZERO, p(100.0, 0.0)]),
        _ => unreachable!(),
    }
    assert_eq!(h.polyline_points(a)[1].x - before[1].x, 50.0);
    assert_ne!(h.origin(a), Point::ZERO);
    assert_ne!(h.origin(b), p(200.0, 0.0));
}

// --- DuplicateState -------------------------------------------------------------------------

#[test]
fn alt_drag_duplicates_a_node_and_leaves_the_original() {
    let mut h = Harness::new();
    let original = h.id(0);
    h.down(p(50.0, 50.0), ALT);
    h.mv(p(70.0, 80.0), ALT);
    h.up(p(70.0, 80.0), ALT);

    assert_eq!(h.ctx.document.nodes().len(), 3);
    assert_eq!(h.origin(original), Point::ZERO);
    let duplicate = h.selection()[0];
    assert_eq!(h.selection().len(), 1);
    assert_ne!(duplicate, original);
    assert_eq!(h.origin(duplicate), p(20.0, 30.0));
}

#[test]
fn alt_drag_duplicates_all_selected_nodes() {
    let mut h = Harness::new();
    let (a, b) = (h.id(0), h.id(1));
    h.click(p(50.0, 50.0), NONE);
    h.click(p(250.0, 50.0), SHIFT);

    h.down(p(50.0, 50.0), ALT);
    h.mv(p(60.0, 60.0), ALT);
    h.up(p(60.0, 60.0), ALT);

    assert_eq!(h.ctx.document.nodes().len(), 4);
    assert_eq!(h.origin(a), Point::ZERO);
    assert_eq!(h.origin(b), p(200.0, 0.0));
    let origins: Vec<Point> = h.selection().iter().map(|id| h.origin(*id)).collect();
    assert_eq!(origins.len(), 2);
    assert!(origins.contains(&p(10.0, 10.0)) && origins.contains(&p(210.0, 10.0)));
}

#[test]
fn pressing_alt_during_a_drag_duplicates_at_the_current_position() {
    let mut h = Harness::new();
    let original = h.id(0);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(70.0, 60.0), NONE);
    h.mv(p(70.0, 60.0), ALT);
    h.mv(p(90.0, 80.0), ALT);
    h.up(p(90.0, 80.0), ALT);

    assert_eq!(h.origin(original), Point::ZERO);
    assert_eq!(h.origin(h.selection()[0]), p(40.0, 30.0));
}

#[test]
fn duplicate_drag_replays_as_one_history_entry() {
    let mut h = Harness::new();
    let original = h.id(0);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(70.0, 80.0), ALT);
    h.mv(p(90.0, 100.0), ALT);
    h.up(p(90.0, 100.0), ALT);
    let duplicate = h.selection()[0];
    let final_origin = h.origin(duplicate);

    h.undo();
    assert!(h.ctx.document.node(duplicate).is_none());
    assert_eq!(h.origin(original), Point::ZERO);
    assert!(!h.ctx.history.can_undo());

    h.redo();
    assert_eq!(h.origin(duplicate), final_origin);
}

// --- Grouping -------------------------------------------------------------------------------

/// Moves the root nodes into a new group at `origin`; returns its id.
fn group_all(h: &mut Harness, origin: Point) -> NodeId {
    let ids = h.ids();
    let children = h.ctx.document.remove_all(None, &ids);
    h.ctx.document.insert(None, Group::new(origin, children).into(), None).unwrap()
}

#[test]
fn click_and_marquee_select_a_group_rather_than_its_descendants() {
    let mut h = Harness::new();
    let group = group_all(&mut h, p(100.0, 200.0));
    let children = h.ctx.document.children(Some(group)).unwrap().len();

    // The point is in the gap between the two children.
    h.click(p(250.0, 250.0), NONE);
    assert_eq!(h.selection(), vec![group]);
    h.ctx.selection.clear_selection();
    h.down(p(240.0, 180.0), NONE);
    h.mv(p(260.0, 260.0), NONE);
    h.up(p(260.0, 260.0), NONE);
    assert_eq!(h.selection(), vec![group]);

    let before = h.json();
    assert!(h.key(Key::Delete, NONE));
    assert!(h.ctx.document.nodes().is_empty());
    assert!(h.selection().is_empty());
    h.undo();
    assert_eq!(h.json(), before);
    assert_eq!(h.ctx.document.children(Some(group)).unwrap().len(), children);
}

#[test]
fn command_g_groups_and_shift_ungroups_with_history() {
    let mut h = Harness::new();
    let ids = h.ids();
    let bounds: Vec<_> = ids.iter().map(|id| h.ctx.document.global_bounds(*id)).collect();
    let before = h.json();
    h.select(ids.clone());

    assert!(h.key(Key::Char('g'), COMMAND));
    assert_eq!(h.ctx.document.nodes().len(), 1);
    let group = h.id(0);
    assert!(h.node(group).as_group().is_some());
    assert_eq!(h.selection(), vec![group]);
    let child_ids: Vec<NodeId> = h.ctx.document.children(Some(group)).unwrap().iter().map(Node::id).collect();
    assert_eq!(child_ids, ids);
    let grouped_bounds: Vec<_> = ids.iter().map(|id| h.ctx.document.global_bounds(*id)).collect();
    assert_eq!(grouped_bounds, bounds);
    let grouped = h.json();

    h.undo();
    assert_eq!(h.json(), before);
    assert!(!h.ctx.history.can_undo());
    h.redo();
    assert_eq!(h.json(), grouped);
    h.select([group]);

    assert!(h.key(Key::Char('g'), COMMAND_SHIFT));
    assert_eq!(h.ids(), ids);
    let ungrouped_bounds: Vec<_> = ids.iter().map(|id| h.ctx.document.global_bounds(*id)).collect();
    assert_eq!(ungrouped_bounds, bounds);
    assert_eq!(h.selection(), ids);
    assert!(ids.iter().all(|id| h.ctx.document.parent_of(*id) == Some(None)));
    let ungrouped = h.json();
    h.undo();
    assert_eq!(h.json(), grouped);
    h.redo();
    assert_eq!(h.json(), ungrouped);
}

#[test]
fn group_shortcuts_leave_empty_and_single_selections_unchanged() {
    let mut h = Harness::new();
    let before = h.json();
    assert!(!h.key(Key::Char('g'), NONE));
    h.select(h.ids());
    assert!(!h.key(Key::Char('g'), NONE));
    h.ctx.selection.clear_selection();
    assert!(!h.key(Key::Char('g'), COMMAND));
    h.select([h.id(0)]);
    assert!(h.key(Key::Char('g'), COMMAND));
    assert!(h.key(Key::Char('g'), COMMAND_SHIFT));
    assert_eq!(h.json(), before);
    assert!(!h.ctx.history.can_undo());
}

#[test]
fn grouping_preserves_sibling_and_child_paint_order() {
    let mut h = Harness::new();
    let (first, second) = (h.id(0), h.id(1));
    let mut copy = h.node(second).copy_with(None, true);
    copy.set_origin(p(400.0, 0.0));
    let third = h.ctx.document.insert(None, copy, None).unwrap();
    h.select([second, first]);

    assert!(h.key(Key::Char('g'), COMMAND));

    let group = h.id(0);
    assert_eq!(h.ids(), vec![group, third]);
    let child_ids: Vec<NodeId> = h.ctx.document.children(Some(group)).unwrap().iter().map(Node::id).collect();
    assert_eq!(child_ids, vec![first, second]);
    h.undo();
    assert_eq!(h.ids(), vec![first, second, third]);
}

#[test]
fn ungrouping_multiple_groups_is_one_undo_entry() {
    let mut h = Harness::new();
    let nodes = h.ctx.document.remove_all(None, &h.ids());
    let mut nodes = nodes.into_iter();
    let first = h.ctx.document.insert(None, Group::new(Point::ZERO, vec![nodes.next().unwrap()]).into(), None).unwrap();
    let second = h.ctx.document.insert(None, Group::new(Point::ZERO, vec![nodes.next().unwrap()]).into(), None).unwrap();
    h.select([first, second]);

    assert!(h.key(Key::Char('g'), COMMAND_SHIFT));

    let groups = |h: &Harness| h.ctx.document.nodes().iter().filter(|n| n.as_group().is_some()).count();
    assert_eq!(groups(&h), 0);
    assert!(h.ctx.history.can_undo());
    h.undo();
    assert_eq!(groups(&h), 2);
    assert!(!h.ctx.history.can_undo());
}

// --- IdleInteractionState -------------------------------------------------------------------

fn label_harness(kind: FeatureKind) -> Harness {
    Harness::with_nodes(vec![Feature::new(Point::ZERO, Size::new(200.0, 48.0), kind).into()])
}

fn shape_style() -> ShapeStyle {
    ShapeStyle { label: "hello world".into(), ..ShapeStyle::default() }
}

#[test]
fn double_clicking_a_labelled_feature_starts_a_label_edit_session() {
    let kinds = [
        FeatureKind::Text(TextKind::new("hello world")),
        FeatureKind::Rectangle(RectangleKind::new(shape_style())),
        FeatureKind::Circle(CircleKind::new(shape_style())),
    ];
    for kind in kinds {
        let mut h = label_harness(kind);
        let id = h.id(0);
        h.double_click(p(50.0, 24.0));

        assert_eq!(h.selection(), vec![id]);
        let session = h.ctx.text_edit.session().expect("session").clone();
        assert_eq!(session.feature_id(), Some(id));
        assert_eq!(session.initial_contents, "hello world");
        assert_eq!(session.layout, h.feature(id).label_layout().unwrap().bounds);
    }
}

#[test]
fn double_clicking_a_non_label_node_does_not_start_text_editing() {
    let mut h = Harness::polyline();
    h.double_click(p(50.0, 50.0));
    assert!(h.ctx.text_edit.session().is_none());
}

#[test]
fn double_clicking_the_canvas_starts_a_create_text_session() {
    let mut h = Harness::new();
    let click = p(150.0, 75.0);
    h.double_click(click);

    let session = h.ctx.text_edit.session().expect("session");
    let TextEditKind::Create { draft } = &session.kind else { panic!("expected create session") };
    assert_eq!(draft.origin, click);
    assert!(session.initial_contents.is_empty());
    assert_eq!(session.layout.top_left(), click);
    assert!(session.layout.width() < 30.0);
}

#[test]
fn delete_and_backspace_delete_selected_nodes_as_one_undo_entry() {
    for key in [Key::Delete, Key::Backspace] {
        let mut h = Harness::new();
        let id = h.id(0);
        h.select([id]);

        assert!(h.key(key, NONE));
        assert!(h.ctx.document.node(id).is_none());
        assert!(h.selection().is_empty());

        h.undo();
        assert!(h.ctx.document.node(id).is_some());
    }
}

#[test]
fn delete_restores_selection_when_it_cannot_start_a_transaction() {
    let mut h = Harness::new();
    let id = h.id(0);
    h.select([id]);
    h.ctx.history.begin(&h.ctx.document, "Pending edit", None).unwrap();

    h.key(Key::Delete, NONE);

    assert_eq!(h.selection(), vec![id]);
    assert!(h.ctx.document.node(id).is_some());
}

#[test]
fn unrelated_keys_are_ignored() {
    let mut h = Harness::new();
    h.select([h.id(0)]);
    assert!(!h.key(Key::Enter, NONE));
    assert_eq!(h.ctx.document.nodes().len(), 2);
}

// --- Cursor and painting --------------------------------------------------------------------

#[test]
fn cursor_follows_the_target_under_the_pointer() {
    let mut h = Harness::new();
    let cursor = |h: &Harness, w| ToolModel::resolve_cursor(&h.ctx, w, &h.camera);
    assert_eq!(cursor(&h, p(500.0, 500.0)), EditorCursor::Basic);
    assert_eq!(cursor(&h, p(50.0, 50.0)), EditorCursor::Grab);
    let id = first_selected(&mut h);
    let corner = h.corner_hit(h.bounds(id));
    assert_eq!(cursor(&h, corner), EditorCursor::ResizeDownRight);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(60.0, 60.0), NONE);
    assert_eq!(cursor(&h, p(60.0, 60.0)), EditorCursor::Grabbing);
}

#[test]
fn selection_overlay_is_screen_constant() {
    let mut h = Harness::new();
    h.select([h.id(0)]);
    let stroke_widths = |camera: &Camera, h: &Harness| {
        let mut painter = Painter::new();
        h.ctx.tool.active().unwrap().paint(&h.ctx, camera, &mut painter);
        painter
            .commands
            .iter()
            .filter_map(|c| match c {
                crate::paint::DrawCmd::Stroke { width, .. } => Some(*width),
                _ => None,
            })
            .collect::<Vec<_>>()
    };
    let near = stroke_widths(&Camera::new(Point::ZERO, 1.0), &h);
    let far = stroke_widths(&Camera::new(Point::ZERO, 2.0), &h);
    assert_eq!(near.len(), 5);
    assert_eq!(far.iter().map(|w| w / 2.0).collect::<Vec<_>>(), near);
}

// --- TranslateState -------------------------------------------------------------------------

#[test]
fn moves_the_selection_relative_to_the_node_that_was_dragged() {
    let nodes = [0.0, 100.0, 200.0].iter().map(|x| rect_feature(*x, 0.0, 50.0, 50.0)).collect();
    let mut h = Harness::with_nodes(nodes);
    for (i, point) in [p(25.0, 25.0), p(125.0, 25.0), p(225.0, 25.0)].into_iter().enumerate() {
        h.click(point, if i > 0 { SHIFT } else { NONE });
    }

    h.down(p(25.0, 25.0), NONE);
    h.mv(p(35.0, 35.0), NONE);

    let origins: Vec<Point> = h.ids().iter().map(|id| h.origin(*id)).collect();
    assert_eq!(origins, vec![p(10.0, 10.0), p(110.0, 10.0), p(210.0, 10.0)]);
}

#[test]
fn moving_nodes_notifies_the_editor_context() {
    let mut h = Harness::new();
    h.down(p(50.0, 50.0), NONE);
    let before = h.ctx.revision();
    h.mv(p(60.0, 60.0), NONE);
    assert!(h.ctx.revision() > before);
}

#[test]
fn a_drag_commits_one_undo_entry() {
    let mut h = Harness::new();
    let id = h.id(0);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(60.0, 60.0), NONE);
    h.mv(p(70.0, 70.0), NONE);
    h.mv(p(80.0, 80.0), NONE);
    assert_eq!(h.origin(id), p(30.0, 30.0));
    assert!(!h.ctx.history.can_undo());

    h.up(p(80.0, 80.0), NONE);
    assert!(h.ctx.history.can_undo());
    h.undo();
    assert_eq!(h.origin(id), Point::ZERO);
}

#[test]
fn a_multi_node_drag_commits_one_undo_entry() {
    let mut h = Harness::new();
    let (a, b) = (h.id(0), h.id(1));
    h.select([a, b]);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(70.0, 70.0), NONE);
    h.up(p(70.0, 70.0), NONE);
    assert_eq!(h.origin(a), p(20.0, 20.0));
    assert_eq!(h.origin(b), p(220.0, 20.0));

    h.undo();
    assert_eq!(h.origin(a), Point::ZERO);
    assert_eq!(h.origin(b), p(200.0, 0.0));
}

#[test]
fn shift_drag_constrains_movement_to_the_dominant_axis() {
    let mut h = Harness::new();
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(80.0, 55.0), SHIFT);
    assert_eq!(h.origin(h.id(0)), p(30.0, 0.0));
}

#[test]
fn escape_cancels_movement_without_recording_history() {
    let mut h = Harness::new();
    let id = h.id(0);
    h.down(p(50.0, 50.0), NONE);
    h.mv(p(70.0, 80.0), NONE);

    assert!(h.key(Key::Escape, NONE));
    h.up(p(70.0, 80.0), NONE);

    assert_eq!(h.origin(id), Point::ZERO);
    assert!(!h.ctx.history.is_active());
    assert!(!h.ctx.history.can_undo());
}

// --- ResizeState ----------------------------------------------------------------------------

#[test]
fn dragging_every_handle_past_the_opposite_edge_flips_the_bounds() {
    let cases = [
        (H::TopLeft, p(150.0, 150.0), Rect::from_ltwh(100.0, 100.0, 50.0, 50.0)),
        (H::Top, p(0.0, 150.0), Rect::from_ltwh(0.0, 100.0, 100.0, 50.0)),
        (H::TopRight, p(-150.0, 150.0), Rect::from_ltwh(-50.0, 100.0, 50.0, 50.0)),
        (H::Right, p(-150.0, 0.0), Rect::from_ltwh(-50.0, 0.0, 50.0, 100.0)),
        (H::BottomRight, p(-150.0, -150.0), Rect::from_ltwh(-50.0, -50.0, 50.0, 50.0)),
        (H::Bottom, p(0.0, -150.0), Rect::from_ltwh(0.0, -50.0, 100.0, 50.0)),
        (H::BottomLeft, p(150.0, -150.0), Rect::from_ltwh(100.0, -50.0, 50.0, 50.0)),
        (H::Left, p(150.0, 0.0), Rect::from_ltwh(100.0, 0.0, 50.0, 100.0)),
    ];
    for (handle, delta, expected) in cases {
        let mut h = Harness::new();
        let id = first_selected(&mut h);
        let down = h.handle_center(id, handle);
        let up = down + delta;
        h.down(down, NONE);
        h.mv(up, NONE);
        h.up(up, NONE);

        assert_eq!(h.bounds(id), expected, "{handle:?}");
        assert!(h.feature(id).size.width >= 0.0 && h.feature(id).size.height >= 0.0);
    }
}

#[test]
fn shift_resizing_past_an_edge_keeps_the_opposite_edge_fixed() {
    let cases = [
        (H::Top, p(0.0, 150.0), Rect::from_ltwh(25.0, 100.0, 50.0, 50.0)),
        (H::Right, p(-150.0, 0.0), Rect::from_ltwh(-50.0, 25.0, 50.0, 50.0)),
        (H::Bottom, p(0.0, -150.0), Rect::from_ltwh(25.0, -50.0, 50.0, 50.0)),
        (H::Left, p(150.0, 0.0), Rect::from_ltwh(100.0, 25.0, 50.0, 50.0)),
    ];
    for (handle, delta, expected) in cases {
        let mut h = Harness::new();
        let id = first_selected(&mut h);
        let down = h.handle_center(id, handle);
        let up = down + delta;
        h.down(down, SHIFT);
        h.mv(up, SHIFT);
        h.up(up, SHIFT);
        assert_eq!(h.bounds(id), expected, "{handle:?}");
    }
}

#[test]
fn crossing_a_corner_keeps_nested_group_geometry_positive() {
    let mut h = Harness::with_nodes(vec![]);
    let feature = rect_feature(0.0, 0.0, 100.0, 100.0);
    let nested = Group::new(Point::ZERO, vec![feature]);
    let outer = h.ctx.document.insert(None, Group::new(p(100.0, 200.0), vec![nested.into()]).into(), None).unwrap();
    let nested_id = h.ctx.document.children(Some(outer)).unwrap()[0].id();
    let feature_id = h.ctx.document.children(Some(nested_id)).unwrap()[0].id();
    h.select([outer]);
    let down = h.handle_center(outer, H::BottomRight);
    let up = down - p(150.0, 150.0);

    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);

    let expected = Rect::from_ltwh(50.0, 150.0, 50.0, 50.0);
    assert_eq!(h.bounds(outer), expected);
    assert_eq!(h.ctx.document.global_bounds(nested_id), Some(expected));
    assert_eq!(h.ctx.document.global_bounds(feature_id), Some(expected));
    assert_eq!(h.feature(feature_id).size, Size::new(50.0, 50.0));
}

#[test]
fn group_drag_scales_children_and_restores_them_through_undo_redo() {
    let mut h = Harness::new();
    let group = group_all(&mut h, p(100.0, 200.0));
    h.select([group]);
    let before = h.json();
    let down = h.corner_hit(h.bounds(group));
    let up = down + p(300.0, 100.0);

    h.down(down, NONE);
    h.mv(down, NONE);
    assert_eq!(h.json(), before);
    h.mv(up, NONE);
    h.up(up, NONE);

    assert_eq!(h.bounds(group), Rect::from_ltwh(100.0, 200.0, 600.0, 200.0));
    let kids: Vec<NodeId> = h.ctx.document.children(Some(group)).unwrap().iter().map(Node::id).collect();
    assert_eq!(h.ctx.document.global_bounds(kids[0]), Some(Rect::from_ltwh(100.0, 200.0, 200.0, 200.0)));
    assert_eq!(h.ctx.document.global_bounds(kids[1]), Some(Rect::from_ltwh(500.0, 200.0, 200.0, 200.0)));
    let after = h.json();
    h.undo();
    assert_eq!(h.json(), before);
    assert!(!h.ctx.history.can_undo());
    h.redo();
    assert_eq!(h.json(), after);
}

#[test]
fn no_snap_on_first_move_when_corner_grab_is_off_centre() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    h.down(down, NONE);
    h.mv(down, NONE);
    assert_eq!(h.bounds(id), bounds);
}

#[test]
fn resizes_a_single_selection_from_the_bottom_right_corner() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let up = p(150.0, 150.0) + (down - bounds.bottom_right());
    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);
    assert_eq!(h.bounds(id), Rect::from_ltwh(0.0, 0.0, 150.0, 150.0));
}

#[test]
fn a_resize_drag_commits_one_undo_entry() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let grab = down - bounds.bottom_right();
    h.down(down, NONE);
    h.mv(p(120.0, 120.0) + grab, NONE);
    h.mv(p(160.0, 160.0) + grab, NONE);
    assert_eq!(h.feature(id).size, Size::new(160.0, 160.0));
    assert!(!h.ctx.history.can_undo());

    h.up(p(160.0, 160.0) + grab, NONE);
    h.undo();
    assert_eq!(h.bounds(id), bounds);
}

#[test]
fn resizes_from_the_top_edge() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Top);
    let up = p(50.0, -50.0) + (down - bounds.top_left());
    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);
    assert_eq!(h.bounds(id), Rect::from_ltwh(0.0, -50.0, 100.0, 150.0));
}

#[test]
fn resizes_from_the_right_edge() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Right);
    let up = p(200.0, 50.0) + (down - bounds.bottom_right());
    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);
    assert_eq!(h.bounds(id), Rect::from_ltwh(0.0, 0.0, 200.0, 100.0));
}

#[test]
fn alt_resize_from_a_corner_is_symmetric_around_the_centre() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let up = p(150.0, 150.0) + (down - bounds.bottom_right());
    h.down(down, ALT);
    h.mv(up, ALT);
    h.up(up, ALT);
    assert_eq!(h.bounds(id).center(), bounds.center());
    assert_eq!(h.feature(id).size, Size::new(200.0, 200.0));
}

#[test]
fn shift_resize_from_a_corner_locks_the_aspect_ratio() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let up = p(200.0, 100.0) + (down - bounds.bottom_right());
    h.down(down, NONE);
    h.mv(up, SHIFT);
    h.up(up, SHIFT);
    close(h.feature(id).size.width, 200.0);
    close(h.feature(id).size.height, 200.0);
}

#[test]
fn shift_resize_from_an_edge_locks_the_aspect_ratio() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Bottom);
    let up = p(50.0, 200.0) + (down - bounds.bottom_right());
    h.down(down, NONE);
    h.mv(up, SHIFT);
    h.up(up, SHIFT);
    close(h.origin(id).y, 0.0);
    close(h.feature(id).size.width, 200.0);
    close(h.feature(id).size.height, 200.0);
}

#[test]
fn alt_resize_from_an_edge_expands_around_the_centre() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Top);
    let up = p(50.0, -50.0) + (down - bounds.top_left());
    h.down(down, ALT);
    h.mv(up, ALT);
    h.up(up, ALT);
    assert_eq!(h.bounds(id).center(), bounds.center());
    assert_eq!(h.feature(id).size, Size::new(100.0, 200.0));
}

#[test]
fn no_snap_on_first_move_when_edge_grab_is_off_centre() {
    let mut h = Harness::new();
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Top) + p(10.0, 0.0);
    h.down(down, NONE);
    h.mv(down, NONE);
    assert_eq!(h.bounds(id), bounds);
}

#[test]
fn no_resize_handles_for_multiple_selections() {
    let mut h = Harness::new();
    h.select(h.ids());
    let bounds = h.bounds(h.id(0));
    let down = h.corner_hit(bounds);
    h.down(down, NONE);
    h.mv(p(150.0, 150.0), NONE);
    h.up(p(150.0, 150.0), NONE);
    assert_eq!(h.bounds(h.id(0)), bounds);
}

#[test]
fn resizing_a_polyline_scales_its_points() {
    let mut h = Harness::polyline();
    let id = h.id(0);
    h.click(p(50.0, 50.0), NONE);
    let end_before = *h.polyline_points(id).last().unwrap();
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let up = p(146.0, 146.0) + (down - bounds.bottom_right());
    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);

    assert_eq!(h.feature(id).size, Size::new(150.0, 150.0));
    assert_ne!(*h.polyline_points(id).last().unwrap(), end_before);
}

fn text_harness(contents: &str) -> Harness {
    Harness::with_nodes(vec![new_text_feature_at(Point::ZERO, contents, None, None).into()])
}

#[test]
fn corner_resize_scales_the_text_font_with_the_drag() {
    let mut h = text_harness("Line one\nLine two");
    let id = first_selected(&mut h);
    let initial = h.text(id).font_size;
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let grab = down - bounds.bottom_right();
    let target = bounds.top_left() + p(bounds.width() * 2.0, bounds.height() * 2.0);
    h.down(down, NONE);
    h.mv(target + grab, NONE);
    h.up(target + grab, NONE);

    close(h.text(id).font_size, initial * 2.0);
    assert_eq!(h.text(id).sizing, TextSizing::Auto);
    assert_eq!(h.origin(id), bounds.top_left());
}

#[test]
fn right_edge_resize_wraps_the_text_without_scaling_it() {
    let mut h = text_harness("one two three four five six");
    let id = first_selected(&mut h);
    let initial = h.text(id).font_size;
    let bounds = h.bounds(id);
    let down = h.edge_hit(bounds, Edge::Right);
    let grab = down - p(bounds.right, bounds.center().y);
    let target = p(bounds.left + 150.0, bounds.center().y);
    h.down(down, NONE);
    h.mv(target + grab, NONE);
    h.up(target + grab, NONE);

    assert_eq!(h.text(id).sizing, TextSizing::FixedWidth);
    assert_eq!(h.text(id).font_size, initial);
    assert_eq!(h.feature(id).width(), 150.0);
    assert!(h.feature(id).height() > bounds.height());
}

#[test]
fn alt_corner_resize_keeps_the_text_centred() {
    let mut h = text_harness("Line one\nLine two");
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let grab = down - bounds.bottom_right();
    let target = bounds.center() + p(bounds.width(), bounds.height());
    h.down(down, ALT);
    h.mv(target + grab, ALT);
    h.up(target + grab, ALT);

    close(h.bounds(id).center().x, bounds.center().x);
    close(h.bounds(id).center().y, bounds.center().y);
    assert!(h.text(id).font_size > 24.0);
}

fn group_with_text(h: &mut Harness, text_origin: Point, contents: &str) -> (NodeId, NodeId) {
    let text = new_text_feature_at(text_origin, contents, None, None);
    let group = Group::new(p(100.0, 100.0), vec![text.into()]);
    let gid = h.ctx.document.insert(None, group.into(), None).unwrap();
    let tid = h.ctx.document.children(Some(gid)).unwrap()[0].id();
    h.select([gid]);
    (gid, tid)
}

#[test]
fn resizing_a_group_with_text_does_not_depend_on_the_drag_path() {
    let mut h = Harness::with_nodes(vec![]);
    let (group, text) = group_with_text(&mut h, p(10.0, 10.0), "Group me");
    let start = h.bounds(group);
    let down = h.corner_hit(start);
    let end = down + p(60.0, 30.0);

    h.down(down, NONE);
    for detour in [p(400.0, 300.0), p(-30.0, 5.0)] {
        h.mv(down + detour, NONE);
    }
    h.mv(end, NONE);
    h.up(end, NONE);
    let direct = h.bounds(group);
    let font_after_detour = h.text(text).font_size;

    h.undo();
    h.down(down, NONE);
    h.mv(end, NONE);
    h.up(end, NONE);

    assert_eq!(h.bounds(group), direct);
    assert_eq!(h.text(text).font_size, font_after_detour);
}

#[test]
fn a_text_corner_keeps_its_aspect_ratio_without_shift() {
    let mut h = text_harness("Line one\nLine two");
    let id = first_selected(&mut h);
    let bounds = h.bounds(id);
    let down = h.corner_hit(bounds);
    let grab = down - bounds.bottom_right();
    // Sideways only: a free corner would leave the height and so reflow.
    let target = bounds.bottom_right() + p(bounds.width(), 0.0);
    h.down(down, NONE);
    h.mv(target + grab, NONE);
    h.up(target + grab, NONE);

    assert_eq!(h.text(id).sizing, TextSizing::Auto);
    close(h.text(id).font_size, 48.0);
    assert_eq!(h.origin(id), bounds.top_left());
}

#[test]
fn a_group_corner_scales_its_text_even_when_dragged_sideways() {
    let mut h = Harness::with_nodes(vec![]);
    let (group, text) = group_with_text(&mut h, Point::ZERO, "one two three four");
    let start = h.bounds(group);
    let down = h.corner_hit(start);
    h.down(down, NONE);
    h.mv(down + p(start.width(), 0.0), NONE);
    h.up(down + p(start.width(), 0.0), NONE);

    assert_eq!(h.text(text).sizing, TextSizing::Auto);
    assert!(h.text(text).font_size > 24.0);
}

#[test]
fn a_group_side_reflows_its_text() {
    let mut h = Harness::with_nodes(vec![]);
    let (group, text) = group_with_text(&mut h, Point::ZERO, "one two three four");
    let start = h.bounds(group);
    let down = h.edge_hit(start, Edge::Right);
    let up = down - p(start.width() / 2.0, 0.0);
    h.down(down, NONE);
    h.mv(up, NONE);
    h.up(up, NONE);

    assert_eq!(h.text(text).sizing, TextSizing::FixedWidth);
    assert_eq!(h.text(text).font_size, 24.0);
}

#[test]
fn text_has_no_top_or_bottom_resize_handles() {
    let h = text_harness("hello");
    let handles: Vec<H> = resize_handles(h.node(h.id(0)), &h.camera).iter().map(|x| x.handle).collect();
    assert!(!handles.contains(&H::Top) && !handles.contains(&H::Bottom));
    assert!(handles.contains(&H::Left));
}

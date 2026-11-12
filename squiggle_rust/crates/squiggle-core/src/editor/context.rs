//! Top-level editor state (`editor_context.dart`), owned by the document UI and passed to tools,
//! renderers and services. Dart's `ChangeNotifier` plumbing is replaced by plain state plus the
//! sub-models' `revision()` counters; `revision()` here sums them for cheap "did anything change".

use crate::camera::Camera;
use crate::document::Document;
use crate::editor::brush_controller::BrushController;
use crate::editor::history::History;
use crate::editor::selection::Selection;
use crate::editor::text_edit::{TextEditModel, TextEditSession};
use crate::editor::tool_model::ToolModel;
use crate::feature::Feature;
use crate::feature_kind::FeatureKind;
use crate::geom::{Point, Rect, Size};
use crate::ids::NodeId;
use crate::tools::tool::Tool;

pub struct EditorContext {
    pub document: Document,
    pub selection: Selection,
    pub tool: ToolModel,
    pub history: History,
    pub text_edit: TextEditModel,
    pub brushes: BrushController,
    /// World-space camera for the current document viewport.
    pub camera: Camera,
    /// Viewport size in screen pixels, written by the viewport widget.
    pub viewport_size: Size,
}

impl EditorContext {
    pub fn new(document: Document) -> Self {
        EditorContext {
            document,
            selection: Selection::new(),
            tool: ToolModel::default(),
            history: History::new(),
            text_edit: TextEditModel::new(),
            brushes: BrushController::new(),
            camera: Camera::default(),
            viewport_size: Size::ZERO,
        }
    }

    /// Changes whenever the document, history, tool, brushes or selection state may have.
    pub fn revision(&self) -> u64 {
        self.history.revision() + self.tool.revision() + self.brushes.revision()
    }

    /// Fresh defaults for the active creation tool with the active brush applied.
    pub fn drawing_inspector_kind(&self) -> Option<FeatureKind> {
        let mut kind = self.tool.active()?.create_drawing_kind()?;
        self.apply_active_brush(&mut kind);
        Some(kind)
    }

    pub fn apply_active_brush(&self, kind: &mut FeatureKind) {
        use crate::brush_apply::BrushApply;
        self.document.session.active_brush().apply_to(kind);
    }

    /// World point at the centre of the viewport, if known.
    pub fn world_center_at_viewport_center(&self) -> Option<Point> {
        (self.viewport_size != Size::ZERO)
            .then(|| self.camera.screen_to_world(Point::new(self.viewport_size.width / 2.0, self.viewport_size.height / 2.0)))
    }

    pub fn cancel_interaction(&mut self) {
        ToolModel::cancel_interaction(self);
    }

    pub fn undo(&mut self) {
        self.cancel_interaction();
        if self.history.can_undo() {
            let _ = self.history.undo(&mut self.document);
            self.refresh_selection_after_history_change();
        }
    }

    pub fn redo(&mut self) {
        self.cancel_interaction();
        if self.history.can_redo() {
            let _ = self.history.redo(&mut self.document);
            self.refresh_selection_after_history_change();
        }
    }

    pub fn set_tool(&mut self, tool: Box<dyn Tool>) {
        ToolModel::set_tool(self, tool);
    }

    pub fn reset_to_select_tool(&mut self) {
        ToolModel::reset_to_select_tool(self);
    }

    /// Selects a newly committed feature when automatic tool switching is enabled.
    pub fn select_created_feature(&mut self, id: NodeId) {
        if !self.tool.is_locked() {
            self.selection.set_selection([id]);
        }
    }

    pub fn start_text_edit(&mut self, session: TextEditSession) {
        let Self { text_edit, document, .. } = self;
        text_edit.begin(document, session);
    }

    /// Opens the inline editor for new text; the document is untouched until it commits non-empty
    /// contents. A `fixed_width` makes it a wrapping box with `world_origin` as its top-left.
    pub fn start_create_text(&mut self, world_origin: Point, fixed_width: Option<f64>) {
        use crate::brush_apply::BrushApply;
        use crate::text_feature_placement::new_text_feature_at;
        let brush = self.document.session.active_brush().clone();
        let configure = |kind: &mut crate::feature_kinds::TextKind| {
            let mut fk = FeatureKind::Text(kind.clone());
            brush.apply_to(&mut fk);
            if let FeatureKind::Text(k) = fk {
                *kind = k;
            }
        };
        let draft: Feature = new_text_feature_at(world_origin, "", fixed_width, Some(&configure));
        let layout = Rect::from_origin_size(draft.origin, draft.size);
        self.start_text_edit(TextEditSession::create(draft, layout));
    }

    pub fn end_text_edit(&mut self) {
        let Self { text_edit, document, .. } = self;
        text_edit.end(document);
    }

    /// Replaces the document contents and resets transient state.
    pub fn load_document(&mut self, new_document: Document) {
        self.cancel_interaction();
        self.end_text_edit();
        self.document.replace_from(&new_document);
        let _ = self.history.clear();
        self.selection.clear_selection();
    }

    fn refresh_selection_after_history_change(&mut self) {
        let alive: Vec<NodeId> =
            self.selection.selected_node_ids().iter().copied().filter(|id| self.document.node(*id).is_some()).collect();
        self.selection.set_selection(alive);
    }
}

impl crate::repositories::DocumentHost for EditorContext {
    fn document(&self) -> &Document {
        &self.document
    }

    fn load_document(&mut self, document: Document) {
        EditorContext::load_document(self, document);
    }
}

//! Drag-to-create tool for box shapes (`create_feature_tool.dart`).

use crate::camera::Camera;
use crate::editor::context::EditorContext;
use crate::feature::Feature;
use crate::feature_geometry::{center_rect_from_points, square_center_rect_from_points, square_rect_from_points};
use crate::feature_kind::FeatureKind;
use crate::feature_kinds::{CircleKind, RectangleKind};
use crate::geom::{Point, Rect};
use crate::paint::Painter;
use crate::tools::tool::{EditorCursor, Modifiers, Tool, ToolId};

enum State {
    Idle,
    Dragging { start: Point, feature: Feature },
}

/// Creates a feature of `kind` by dragging out its bounds (Shift: square, Alt: from center).
pub struct CreateFeatureTool {
    kind: FeatureKind,
    state: State,
}

impl CreateFeatureTool {
    pub fn new(kind: FeatureKind) -> Self {
        CreateFeatureTool { kind, state: State::Idle }
    }

    pub fn rect() -> Self {
        Self::new(FeatureKind::Rectangle(RectangleKind::default()))
    }

    pub fn circle() -> Self {
        Self::new(FeatureKind::Circle(CircleKind::default()))
    }

    /// The template kind this tool creates.
    pub fn kind(&self) -> &FeatureKind {
        &self.kind
    }

    pub fn is_dragging(&self) -> bool {
        matches!(self.state, State::Dragging { .. })
    }

    fn styled_kind(&self, ctx: &EditorContext) -> FeatureKind {
        let mut kind = self.kind.clone();
        ctx.apply_active_brush(&mut kind);
        kind
    }
}

fn bounds_from_drag(start: Point, end: Point, mods: Modifiers) -> Rect {
    match (mods.alt, mods.shift) {
        (true, true) => square_center_rect_from_points(start, end),
        (true, false) => center_rect_from_points(start, end),
        (false, true) => square_rect_from_points(start, end),
        (false, false) => Rect::from_points(start, end),
    }
}

impl Tool for CreateFeatureTool {
    fn id(&self) -> ToolId {
        if matches!(self.kind, FeatureKind::Circle(_)) { ToolId::Circle } else { ToolId::Rectangle }
    }

    fn create_drawing_kind(&self) -> Option<FeatureKind> {
        Some(self.kind.clone())
    }

    fn refresh_brush_preview(&mut self, ctx: &mut EditorContext) {
        let fresh = self.styled_kind(ctx);
        if let State::Dragging { feature, .. } = &mut self.state {
            feature.kind = fresh;
        }
    }

    fn resolve_cursor(&self, _: &EditorContext, _: Point, _: &Camera) -> EditorCursor {
        EditorCursor::Crosshair
    }

    fn paint(&self, _: &EditorContext, _: &Camera, painter: &mut Painter) {
        if let State::Dragging { feature, .. } = &self.state {
            feature.paint(painter);
        }
    }

    fn deactivate(&mut self, ctx: &mut EditorContext) {
        self.cancel_interaction(ctx);
    }

    fn cancel_interaction(&mut self, _: &mut EditorContext) {
        self.state = State::Idle;
    }

    fn on_pointer_down(&mut self, _: &mut EditorContext, _: Point, _: &Camera, _: Modifiers) -> bool {
        true
    }

    fn on_pointer_move(&mut self, ctx: &mut EditorContext, world: Point, _: &Camera, mods: Modifiers) -> bool {
        match &mut self.state {
            State::Idle => {
                let bounds = if mods.alt {
                    Rect::from_center(world, 1.0, 1.0)
                } else {
                    Rect::from_ltwh(world.x, world.y, 1.0, 1.0)
                };
                let feature = Feature::new(bounds.top_left(), bounds.size(), self.styled_kind(ctx));
                self.state = State::Dragging { start: world, feature };
            }
            State::Dragging { start, feature } => feature.set_bounds(bounds_from_drag(*start, world, mods)),
        }
        true
    }

    fn on_pointer_up(&mut self, ctx: &mut EditorContext, _: Point, _: &Camera, _: Modifiers) -> bool {
        if let State::Dragging { feature, .. } = std::mem::replace(&mut self.state, State::Idle) {
            let created = ctx.history.run(&mut ctx.document, "Create feature", None, |tx| tx.add(feature, None));
            if let Ok(id) = created {
                ctx.select_created_feature(id);
            }
            ctx.reset_to_select_tool();
        }
        true
    }
}

#[cfg(test)]
mod tests;

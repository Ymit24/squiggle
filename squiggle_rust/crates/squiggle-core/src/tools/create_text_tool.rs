//! Click to place auto-sized text; drag to set the width it wraps at (`create_text_tool.dart`).

use crate::camera::Camera;
use crate::document_colors::squiggle_colors::ACCENT;
use crate::editor::context::EditorContext;
use crate::feature_kind::FeatureKind;
use crate::feature_kinds::TextKind;
use crate::geom::{Point, Rect};
use crate::paint::{Cap, Painter};
use crate::tools::tool::{EditorCursor, Modifiers, Tool};

/// Screen pixels the pointer must travel sideways before a press counts as a drag; the dragged
/// width is what matters, not the height.
const DRAG_THRESHOLD: f64 = 6.0;

#[derive(Default)]
pub struct CreateTextTool {
    press_world: Option<Point>,
    drag_rect: Option<Rect>,
}

impl CreateTextTool {
    pub fn new() -> Self {
        Self::default()
    }

    fn reset(&mut self) {
        self.press_world = None;
        self.drag_rect = None;
    }
}

impl Tool for CreateTextTool {
    fn create_drawing_kind(&self) -> Option<FeatureKind> {
        Some(FeatureKind::Text(TextKind::new("")))
    }

    fn resolve_cursor(&self, _: &EditorContext, _: Point, _: &Camera) -> EditorCursor {
        EditorCursor::Crosshair
    }

    fn paint(&self, _: &EditorContext, camera: &Camera, painter: &mut Painter) {
        let Some(r) = self.drag_rect else { return };
        let corners = [r.top_left(), r.top_right(), r.bottom_right(), r.bottom_left()];
        painter.stroke(&corners, true, camera.screen_length_to_world_length(1.0), ACCENT, Cap::Butt);
    }

    fn deactivate(&mut self, _: &mut EditorContext) {
        self.reset();
    }

    fn on_pointer_down(&mut self, _: &mut EditorContext, world: Point, _: &Camera, _: Modifiers) -> bool {
        self.press_world = Some(world);
        true
    }

    fn on_pointer_move(&mut self, _: &mut EditorContext, world: Point, camera: &Camera, _: Modifiers) -> bool {
        let Some(press) = self.press_world else { return false };
        let travelled = camera.world_length_to_screen_length((world.x - press.x).abs());
        if travelled < DRAG_THRESHOLD && self.drag_rect.is_none() {
            return false;
        }
        self.drag_rect = Some(Rect::from_points(press, world));
        true
    }

    fn on_pointer_up(&mut self, ctx: &mut EditorContext, world: Point, _: &Camera, _: Modifiers) -> bool {
        let rect = self.drag_rect;
        let fixed_width = rect.map(|r| r.width()).filter(|w| *w > 0.0);
        let origin = rect.map(|r| r.top_left()).or(self.press_world).unwrap_or(world);
        ctx.start_create_text(origin, fixed_width);
        self.reset();
        ctx.reset_to_select_tool();
        true
    }
}

#[cfg(test)]
mod tests;

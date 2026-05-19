use gpui::{BorderStyle, Bounds, Pixels, Point, Size, Window, outline, point, px, rgb};

use crate::{
    app::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature_id::FeatureId,
};

pub struct CreateRect {}

impl CreateRect {
    pub fn new() -> Self {
        Self {}
    }

    pub fn on_mouse_down(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
    }

    pub fn on_mouse_move(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        is_dragging: bool,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
    }

    pub fn on_mouse_up(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {}
}

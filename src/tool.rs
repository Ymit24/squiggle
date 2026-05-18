use gpui::{Pixels, Point, Window, px};

use crate::{app::SelectionState, camera::Camera, document::Document, tools::select::SelectTool};

pub enum Tool {
    Selection(SelectTool),
}

impl Tool {
    pub fn new_selection() -> Self {
        Self::Selection(SelectTool::new())
    }

    pub fn on_mouse_down(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        match self {
            Self::Selection(tool) => {
                tool.on_mouse_down(document, mouse_world, selection_state, shift)
            }
        }
    }

    pub fn on_mouse_move(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        is_dragging: bool,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        match self {
            Self::Selection(tool) => {
                tool.on_mouse_move(document, mouse_world, is_dragging, selection_state, shift)
            }
        }
    }

    pub fn on_mouse_up(
        &mut self,
        document: &Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        match self {
            Self::Selection(tool) => {
                tool.on_mouse_up(document, mouse_world, selection_state, shift)
            }
        }
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        match self {
            Self::Selection(tool) => tool.render(window, camera),
        }
    }
}

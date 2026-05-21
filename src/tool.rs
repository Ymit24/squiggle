use gpui::{Pixels, Point, Window};

use crate::{
    editor::SelectionState,
    camera::Camera,
    document::Document,
    tools::{create_rect::CreateRect, select::SelectTool},
};

pub enum Tool {
    Selection(SelectTool),
    CreateRect(CreateRect),
}

impl Tool {
    pub fn new_selection() -> Self {
        Self::Selection(SelectTool::new())
    }

    pub fn new_create_rect() -> Self {
        Self::CreateRect(CreateRect::new())
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
            Self::CreateRect(tool) => {
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
            Self::CreateRect(tool) => {
                tool.on_mouse_move(document, mouse_world, is_dragging, selection_state, shift)
            }
        }
    }

    pub fn on_mouse_up(
        &mut self,
        document: &mut Document,
        mouse_world: Point<Pixels>,
        selection_state: &mut SelectionState,
        shift: bool,
    ) {
        match self {
            Self::Selection(tool) => {
                tool.on_mouse_up(document, mouse_world, selection_state, shift)
            }
            Self::CreateRect(tool) => {
                tool.on_mouse_up(document, mouse_world, selection_state, shift)
            }
        }
    }

    pub fn deactivate(&mut self, selection_state: &mut SelectionState) {
        match self {
            Self::Selection(tool) => tool.deactivate(selection_state),
            Self::CreateRect(tool) => tool.deactivate(selection_state),
        }
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        match self {
            Self::Selection(tool) => tool.render(window, camera),
            Self::CreateRect(tool) => tool.render(window, camera),
        }
    }
}

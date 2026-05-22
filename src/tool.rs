use gpui::{App, Pixels, Point, Window};

use crate::{
    camera::Camera, document::Document, editor::SelectionState, feature::Feature, tools::{create_feature::CreateFeature, select::SelectTool}
};

#[derive(Clone)]
pub enum Tool {
    Selection(SelectTool),
    CreateRect(CreateFeature),
    CreateCircle(CreateFeature),
}

impl Tool {
    pub fn new_selection() -> Self {
        Self::Selection(SelectTool::new())
    }

    pub fn new_create_rect(ghost: Feature) -> Self {
        Self::CreateRect(CreateFeature::new(ghost))
    }

    pub fn new_create_circle(ghost: Feature) -> Self {
        Self::CreateCircle(CreateFeature::new(ghost))
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
            Self::CreateCircle(tool) => {
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
            Self::CreateCircle(tool) => {
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
            Self::CreateCircle(tool) => {
                tool.on_mouse_up(document, mouse_world, selection_state, shift)
            }
        }
    }

    pub fn deactivate(&mut self, selection_state: &mut SelectionState) {
        match self {
            Self::Selection(tool) => tool.deactivate(selection_state),
            Self::CreateRect(tool) => tool.deactivate(selection_state),
            Self::CreateCircle(tool) => tool.deactivate(selection_state),
        }
    }

    pub fn render(&self, window: &mut Window, camera: &Camera, cx: &mut App) {
        match self {
            Self::Selection(tool) => tool.render(window, camera),
            Self::CreateRect(tool) => tool.render(window, camera, cx),
            Self::CreateCircle(tool) => tool.render(window, camera, cx),
        }
    }
}

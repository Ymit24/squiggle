use gpui::{Bounds, Pixels, Point, Size, Window, px};

use crate::{
    editor::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature::Feature,
};

pub struct CreateFeature {
    state: FSM,
    ghost: Feature,
}

enum FSM {
    Idle,
    Dragging {
        start: Point<Pixels>,
    },
}

impl CreateFeature {
    pub fn new(ghost: Feature) -> Self {
        Self { state: FSM::Idle, ghost }
    }

    pub fn on_mouse_down(
        &mut self,
        _document: &Document,
        _mouse_world: Point<Pixels>,
        _selection_state: &mut SelectionState,
        _shift: bool,
    ) {
    }

    pub fn on_mouse_move(
        &mut self,
        _document: &mut Document,
        mouse_world: Point<Pixels>,
        is_dragging: bool,
        _selection_state: &mut SelectionState,
        _shift: bool,
    ) {
        if !is_dragging {
            return;
        }

        match self.state {
            FSM::Idle => {
                self.state = FSM::Dragging {
                    start: mouse_world,
                };
                self.ghost.set_bounds(Bounds::new(mouse_world, Size::new(px(1.), px(1.))));   
            }
            FSM::Dragging {
                start,
            } => {
                let min_point = start.min(&mouse_world);
                let max_point = start.max(&mouse_world);
                let new_bounds = Bounds::new(min_point, Size::from(max_point - min_point));
                self.ghost.set_bounds(new_bounds);
            }
        };
    }

    pub fn on_mouse_up(
        &mut self,
        document: &mut Document,
        _mouse_world: Point<Pixels>,
        _selection_state: &mut SelectionState,
        _shift: bool,
    ) {
        
        if let FSM::Dragging { .. } = self.state {
            document.execute_command(Command::AddFeature(self.ghost.clone()));
            self.state = FSM::Idle;
        }
    }

    pub fn deactivate(&mut self, _selection_state: &mut SelectionState) {}

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        match self.state {
            FSM::Idle => {}
            FSM::Dragging { .. } => {
                let screen_bounds = camera.world_to_screen_bounds(self.ghost.bounds());

                self.ghost.render(screen_bounds, window);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::editor::SelectionState;
    use crate::document::Document;
    use gpui::{point, px};

    fn doc_with_features(features: Vec<Feature>) -> Document {
        Document::new(features)
    }

    fn point_px(x: f32, y: f32) -> Point<Pixels> {
        point(px(x), px(y))
    }

    #[test]
    fn test_clicking_down_then_release_without_drag_does_nothing() {
        let mut tool = CreateFeature::new(Feature::new_rectangle(px(0.), px(0.), px(1.), px(1.)));
        let mut doc = doc_with_features(vec![]);
        let mut selection_state = SelectionState::new();

        tool.on_mouse_down(&doc, point_px(0., 0.), &mut selection_state, false);
        tool.on_mouse_up(&mut doc, point_px(0., 0.), &mut selection_state, false);

        assert!(doc.features.is_empty());
    }

    #[test]
    fn test_clicking_down_then_moving_then_releasing_creates_rect() {
        let mut tool = CreateFeature::new(Feature::new_rectangle(px(0.), px(0.), px(1.), px(1.)));
        let mut doc = doc_with_features(vec![]);
        let mut selection_state = SelectionState::new();

        tool.on_mouse_down(&doc, point_px(0., 0.), &mut selection_state, false);
        tool.on_mouse_move(
            &mut doc,
            point_px(0., 0.),
            true,
            &mut selection_state,
            false,
        );
        tool.on_mouse_move(
            &mut doc,
            point_px(100., 100.),
            true,
            &mut selection_state,
            false,
        );
        tool.on_mouse_up(&mut doc, point_px(100., 100.), &mut selection_state, false);

        assert_eq!(doc.features.len(), 1);
    }
}

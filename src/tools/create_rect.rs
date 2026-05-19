use gpui::{Bounds, Pixels, Point, Size, Window, px};

use crate::{
    app::SelectionState,
    camera::Camera,
    document::{Command, Document},
    feature::Feature,
};

pub struct CreateRect {
    state: FSM,
}

enum FSM {
    Idle,
    Dragging {
        start: Point<Pixels>,
        ghost: Feature,
    },
}

impl CreateRect {
    pub fn new() -> Self {
        Self { state: FSM::Idle }
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
                    ghost: Feature::new_rectangle(mouse_world.x, mouse_world.y, px(1.), px(1.)),
                };
            }
            FSM::Dragging {
                start,
                ref mut ghost,
            } => {
                let new_bounds = Bounds::new(start, Size::from(mouse_world - start));
                ghost.set_bounds(new_bounds);
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
        if let FSM::Dragging { ghost, .. } = self.state {
            document.execute_command(Command::AddFeature(ghost.clone()));
            self.state = FSM::Idle;
        }
    }

    pub fn render(&self, window: &mut Window, camera: &Camera) {
        match self.state {
            FSM::Idle => {}
            FSM::Dragging { ghost, .. } => {
                let screen_bounds = camera.world_to_screen_bounds(ghost.bounds());

                ghost.render(screen_bounds, window);
            }
        }
    }
}
